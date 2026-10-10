import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:clipboard_feature/clipboard_feature.dart';
import 'package:notifications_feature/notifications_feature.dart';
import 'package:sms_feature/sms_feature.dart';
import 'package:device_status_feature/device_status_feature.dart';
import 'package:otp_feature/otp_feature.dart';
import 'package:file_transfer_feature/file_transfer_feature.dart';
import 'package:remote_control_feature/remote_control_feature.dart';

/// Central Android controller coordinating background services, native platform integrations,
/// network transport (client/server), feature plugins, and UI state.
class PhoneAppController {
  final String localDeviceId;
  final String deviceName;

  BridgeServer? _server;
  final FeatureRegistry registry = FeatureRegistry();
  final EventBus eventBus = EventBus();
  final AndroidBridgePlatform platform;

  // Feature plugins
  late final ClipboardFeature clipboard;
  late final NotificationsFeature notifications;
  late final SmsFeature sms;
  late final DeviceStatusFeature deviceStatus;
  late final OtpFeature otp;
  late final FileTransferFeature fileTransfer;
  late final RemoteControlFeature remoteControl;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<String> _ringAlertController =
      StreamController<String>.broadcast();

  ConnectionStatus _connectionStatus = ConnectionStatus.initial();
  TransportChannel? _activeChannel;
  StreamSubscription<Envelope>? _incomingSub;

  int _batteryLevel = 100;
  bool _isCharging = false;

  PhoneAppController({
    String? localDeviceId,
    this.deviceName = 'Android Device',
    AndroidBridgePlatform? platform,
  })  : localDeviceId =
            localDeviceId ?? 'phone-${CryptoUtils.generateNumericOtp(6)}',
        platform = platform ?? AndroidBridgePlatform.instance {
    _initializeFeatures();
    _setupPlatformInteractions();
  }

  ConnectionStatus get connectionStatus => _connectionStatus;
  Stream<ConnectionStatus> get onStatusChanged => _statusController.stream;
  Stream<String> get onRingAlert => _ringAlertController.stream;
  bool get isConnected => _activeChannel?.isOpen ?? false;
  int get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;

  void _initializeFeatures() {
    clipboard = ClipboardFeature(localDeviceId: localDeviceId);
    notifications = NotificationsFeature();
    sms = SmsFeature();
    deviceStatus = DeviceStatusFeature();
    otp = OtpFeature();
    fileTransfer = FileTransferFeature(localDeviceId: localDeviceId);
    remoteControl = RemoteControlFeature();

    // Register all feature plugins
    registry.register(clipboard);
    registry.register(notifications);
    registry.register(sms);
    registry.register(deviceStatus);
    registry.register(otp);
    registry.register(fileTransfer);
    registry.register(remoteControl);

    // Sync incoming clipboard from Mac into native Android clipboard
    clipboard.onClipboardChanged.listen((clipItem) async {
      if (clipItem.originDeviceId != localDeviceId) {
        await platform.copyToClipboard(clipItem.content);
      }
    });

    // Handle outbound SMS dispatch request from Mac
    sms.onSendRequested = (payload, messageId) async {
      final success = await platform.sendSms(
        address: payload.address,
        body: payload.body,
        simSlot: payload.simSlot,
        clientMessageId: payload.clientMessageId,
      );
      if (payload.clientMessageId != null) {
        sms.confirmDelivery(
          clientMessageId: payload.clientMessageId!,
          success: success,
          errorMessage: success ? null : 'Failed to dispatch SMS via platform',
        );
      }
    };

    // Handle "Find My Phone" alert request from Mac
    deviceStatus.onRingRequested = ([reason]) {
      _ringAlertController.add(reason ?? 'Find My Phone');
    };
  }

  void _setupPlatformInteractions() {
    platform.registerCallbacks(
      onNotificationPosted: (notifMap) {
        final item = NotificationItem(
          key: notifMap['key'] as String? ??
              'notif-${DateTime.now().millisecondsSinceEpoch}',
          packageName:
              notifMap['packageName'] as String? ?? 'com.android.unknown',
          appName: notifMap['appName'] as String? ?? 'App',
          title: notifMap['title'] as String? ?? '',
          text: notifMap['text'] as String? ?? '',
          postedAt: DateTime.fromMillisecondsSinceEpoch(
              notifMap['postTime'] as int? ??
                  DateTime.now().millisecondsSinceEpoch),
          canReply: notifMap['canReply'] as bool? ?? false,
        );
        notifications.postNotification(item);
      },
      onNotificationDismissed: (key) {
        notifications.dismissNotification(key);
      },
      onSmsReceived: (smsMap) {
        final address = smsMap['address'] as String? ?? 'Unknown';
        final body = smsMap['body'] as String? ?? '';
        final timestamp = smsMap['timestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch;
        final messageId = smsMap['messageId'] as String? ??
            'sms-${DateTime.now().millisecondsSinceEpoch}';
        final threadId = smsMap['threadId'] as String? ?? address;

        sms.receiveSms(
          messageId: messageId,
          threadId: threadId,
          address: address,
          body: body,
          timestamp: timestamp,
        );
      },
      onClipboardCaptured: (text) {
        // Triggered explicitly via Quick Settings Tile or Share Sheet
        clipboard.syncOutbound(text);
      },
      onBatteryChanged: (level, charging) {
        _batteryLevel = level;
        _isCharging = charging;
        if (isConnected) {
          deviceStatus.broadcastLocalStatus(
            batteryLevel: level,
            isCharging: charging,
            networkType: 'wifi',
          );
        }
      },
    );
  }

  /// Starts the Android persistent Foreground Service and begins network readiness.
  Future<void> startService({int port = 8765}) async {
    await platform.startForegroundService();
    _server = BridgeServer(port: port);
    await _server!.start();
    _server!.onConnection.listen((channel) {
      handleConnection(channel);
    });

    _updateStatus(ConnectionState.discovering);
  }

  /// Connects directly to a Mac host (e.g. resolved via mDNS or manual IP).
  Future<void> connectTo(Uri uri) async {
    _updateStatus(ConnectionState.connecting);
    try {
      final channel = await BridgeClient.connect(uri);
      await handleConnection(channel);
    } catch (e) {
      _updateStatus(ConnectionState.error, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Handles established transport connection.
  Future<void> handleConnection(TransportChannel channel) async {
    await _incomingSub?.cancel();
    _activeChannel = channel;

    _updateStatus(ConnectionState.handshaking);

    _incomingSub = channel.incoming.listen((envelope) async {
      if (envelope.type == HelloPayload.messageType) {
        await _handleHello(envelope);
      } else if (envelope.type == HelloAckPayload.messageType) {
        await _handleHelloAck(envelope);
      } else {
        registry.dispatch(envelope);
      }
    }, onDone: () {
      disconnect();
    });

    // Send 'hello' handshake advertising Android provider capabilities
    final helloEnvelope = Envelope.create(
      type: HelloPayload.messageType,
      payload: HelloPayload(
        deviceId: localDeviceId,
        name: deviceName,
        platform: 'android',
        appVersion: '1.0.0',
        protocolVersion: 1,
        capabilities: registry.supportedCapabilities,
      ).toMap(),
    );

    channel.send(helloEnvelope);
  }

  Future<void> _handleHello(Envelope envelope) async {
    final hello = HelloPayload.fromMap(envelope.payload);
    final context = FeatureContext(
      peerDeviceId: hello.deviceId,
      channel: _activeChannel!,
    );

    final agreed = registry.supportedCapabilities
        .where((c) => hello.capabilities.contains(c))
        .toList();

    await registry.startAgreedFeatures(context, agreed);

    final ack = Envelope.create(
      type: HelloAckPayload.messageType,
      ref: envelope.id,
      payload: HelloAckPayload(
        accepted: true,
        deviceId: localDeviceId,
        agreedCapabilities: agreed,
      ).toMap(),
    );

    _activeChannel?.send(ack);

    _updateStatus(
      ConnectionState.connected,
      peerDeviceId: hello.deviceId,
    );

    // Broadcast initial battery telemetry
    deviceStatus.broadcastLocalStatus(
      batteryLevel: _batteryLevel,
      isCharging: _isCharging,
      networkType: 'wifi',
    );
  }

  Future<void> _handleHelloAck(Envelope envelope) async {
    final ack = HelloAckPayload.fromMap(envelope.payload);
    if (!ack.accepted) {
      await disconnect();
      return;
    }

    final context = FeatureContext(
      peerDeviceId: ack.deviceId,
      channel: _activeChannel!,
    );

    await registry.startAgreedFeatures(context, ack.agreedCapabilities);

    _updateStatus(
      ConnectionState.connected,
      peerDeviceId: ack.deviceId,
    );

    // Broadcast initial battery status to peer
    deviceStatus.broadcastLocalStatus(
      batteryLevel: _batteryLevel,
      isCharging: _isCharging,
      networkType: 'wifi',
    );
  }

  /// Disconnects active peer connection.
  Future<void> disconnect() async {
    await _incomingSub?.cancel();
    _incomingSub = null;
    await registry.stopAll();
    await _activeChannel?.close();
    _activeChannel = null;

    _updateStatus(ConnectionState.disconnected);
  }

  /// Stops server, terminates background service, and disposes resources.
  Future<void> stop() async {
    await disconnect();
    await _server?.stop();
    _server = null;
    await platform.stopForegroundService();
    await _statusController.close();
    await _ringAlertController.close();
    eventBus.dispose();
  }

  void _updateStatus(
    ConnectionState state, {
    String? peerDeviceId,
    String? errorMessage,
  }) {
    _connectionStatus = ConnectionStatus(
      state: state,
      peerDeviceId: peerDeviceId ?? _connectionStatus.peerDeviceId,
      errorMessage: errorMessage,
      updatedAt: DateTime.now(),
    );
    _statusController.add(_connectionStatus);
  }
}
