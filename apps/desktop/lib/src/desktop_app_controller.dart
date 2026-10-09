import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:bridge_ui/bridge_ui.dart';
import 'package:clipboard_feature/clipboard_feature.dart';
import 'package:notifications_feature/notifications_feature.dart';
import 'package:sms_feature/sms_feature.dart';
import 'package:device_status_feature/device_status_feature.dart';
import 'package:otp_feature/otp_feature.dart';
import 'package:file_transfer_feature/file_transfer_feature.dart';
import 'package:remote_control_feature/remote_control_feature.dart';

/// Central macOS controller orchestrating transport, feature plugins, native AppKit integration, and UI state.
class DesktopAppController {
  final String localDeviceId;
  final String deviceName;

  final BridgeServer server;
  final FeatureRegistry registry = FeatureRegistry();
  final EventBus eventBus = EventBus();
  final MacOsBridgePlatform platform;

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

  ConnectionStatus _connectionStatus = ConnectionStatus.initial();
  TransportChannel? _activeChannel;
  StreamSubscription<Envelope>? _incomingSub;

  DesktopAppController({
    String? localDeviceId,
    this.deviceName = 'MacBook Pro',
    int port = 8765,
    MacOsBridgePlatform? platform,
  })  : localDeviceId = localDeviceId ?? 'mac-${CryptoUtils.generateNumericOtp(6)}',
        server = BridgeServer(port: port),
        platform = platform ?? MacOsBridgePlatform.instance {
    _initializeFeatures();
    _setupPlatformInteractions();
  }

  ConnectionStatus get connectionStatus => _connectionStatus;
  Stream<ConnectionStatus> get onStatusChanged => _statusController.stream;
  bool get isConnected => _activeChannel?.isOpen ?? false;

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

    // Automation: Auto-copy detected OTP codes to pasteboard and show native notification
    otp.onOtp.listen((otpItem) async {
      await platform.copyToPasteboard(otpItem.code);
      await platform.showNotification(
        identifier: 'otp-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Код подтверждения скопирован',
        subtitle: otpItem.sender,
        body: '${otpItem.code} скопирован в буфер обмена',
        canReply: false,
      );
    });

    // Mirroring: Show native macOS notifications when phone notifies
    notifications.onNotification.listen((item) async {
      await platform.showNotification(
        identifier: item.key,
        title: item.appName,
        subtitle: item.title,
        body: item.text,
        canReply: item.canReply,
      );
    });

    // Telemetry: Update menu bar tray tooltip and badge on phone battery update
    deviceStatus.onStatusChanged.listen((status) async {
      await platform.updateTray(
        tooltip: 'AndroMac: ${status.batteryLevel}% (${status.networkType})',
        isConnected: true,
        batteryBadge: '${status.batteryLevel}%',
      );
    });

    // Clipboard: Write incoming phone clipboard to macOS native pasteboard
    clipboard.onClipboardChanged.listen((clipItem) async {
      if (clipItem.originDeviceId != localDeviceId) {
        await platform.copyToPasteboard(clipItem.content);
      }
    });
  }

  void _setupPlatformInteractions() {
    platform.registerCallbacks(
      onNotificationAction: (identifier, actionId, replyText) {
        if (replyText != null) {
          notifications.replyToNotification(identifier, replyText, actionId: actionId);
        }
      },
      onNotificationDismissed: (identifier) {
        notifications.dismissNotification(identifier);
      },
      onSystemSleep: () {
        disconnect();
      },
      onSystemWake: () {
        // Ready for reconnection
      },
      onPasteboardChanged: (text) {
        clipboard.syncOutbound(text);
      },
    );
  }

  /// Starts the server and listens for incoming connections.
  Future<void> start() async {
    await server.start();
    server.onConnection.listen((channel) {
      handleConnection(channel);
    });

    _updateStatus(ConnectionState.discovering);
    await platform.updateTray(
      tooltip: 'AndroMac: Ожидание подключения...',
      isConnected: false,
    );
  }

  /// Manually connects to a remote phone host.
  Future<void> connectTo(Uri uri) async {
    _updateStatus(ConnectionState.connecting);
    final channel = await BridgeClient.connect(uri);
    await handleConnection(channel);
  }

  /// Handles newly established transport connection.
  Future<void> handleConnection(TransportChannel channel) async {
    await _incomingSub?.cancel();
    _activeChannel = channel;

    _updateStatus(ConnectionState.handshaking);

    _incomingSub = channel.incoming.listen((envelope) async {
      if (envelope.type == HelloPayload.messageType) {
        await _handleHello(envelope);
      } else {
        registry.dispatch(envelope);
      }
    }, onDone: () {
      disconnect();
    });

    // Send 'hello' handshake
    final helloEnvelope = Envelope.create(
      type: HelloPayload.messageType,
      payload: HelloPayload(
        deviceId: localDeviceId,
        name: deviceName,
        platform: 'macos',
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

    // Agree on shared capabilities and start features
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

    await platform.updateTray(
      tooltip: 'AndroMac: Подключено к ${hello.name}',
      isConnected: true,
    );
  }

  /// Disconnects the active peer connection.
  Future<void> disconnect() async {
    await _incomingSub?.cancel();
    _incomingSub = null;
    await registry.stopAll();
    await _activeChannel?.close();
    _activeChannel = null;

    _updateStatus(ConnectionState.disconnected);
    await platform.updateTray(
      tooltip: 'AndroMac: Отключено',
      isConnected: false,
    );
  }

  /// Stops server and cleans up all resources.
  Future<void> stop() async {
    await disconnect();
    await server.stop();
    await _statusController.close();
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
