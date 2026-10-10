import 'package:meta/meta.dart';
import 'package:bridge_ui/bridge_ui.dart';
import '../desktop_app_view_model.dart';

/// Presentation model and view coordinator for the main macOS window.
@immutable
class DesktopMainWindowViewConfig {
  final DesktopTab activeTab;
  final bool isConnected;
  final String? peerDeviceName;
  final String? peerDeviceId;
  final int? batteryLevel;
  final bool isCharging;
  final List<NotificationTileConfig> notifications;
  final List<SmsConversationTileConfig> conversations;
  final List<SmsMessageBubbleConfig> activeMessages;
  final String? selectedThreadId;
  final List<ClipboardTileConfig> clipboardHistory;
  final List<FileTransferCardConfig> fileTransfers;
  final DiagnosticsChecklistConfig diagnostics;
  final BridgeLocale currentLocale;

  const DesktopMainWindowViewConfig({
    this.activeTab = DesktopTab.devices,
    this.isConnected = false,
    this.peerDeviceName,
    this.peerDeviceId,
    this.batteryLevel,
    this.isCharging = false,
    this.notifications = const [],
    this.conversations = const [],
    this.activeMessages = const [],
    this.selectedThreadId,
    this.clipboardHistory = const [],
    this.fileTransfers = const [],
    required this.diagnostics,
    this.currentLocale = BridgeLocale.ru,
  });

  /// Localized UI strings based on the currently selected locale.
  BridgeStrings get strings => BridgeL10n.forLocale(currentLocale);

  /// Status badge configuration.
  StatusBadgeConfig get statusBadge => isConnected
      ? StatusBadgeConfig.connected(customLabel: strings.connected)
      : StatusBadgeConfig.disconnected(customLabel: strings.disconnected);

  /// Battery indicator configuration.
  BatteryIndicatorConfig? get batteryIndicator => batteryLevel != null
      ? BatteryIndicatorConfig(
          batteryLevel: batteryLevel!,
          isCharging: isCharging,
        )
      : null;

  /// Peer device status card configuration.
  DeviceStatusCardConfig get peerStatusCard => DeviceStatusCardConfig(
        deviceName: peerDeviceName ?? 'Android Device',
        platform: 'android',
        isConnected: isConnected,
        batteryLevel: batteryLevel ?? 100,
        isCharging: isCharging,
        networkType: 'wifi',
      );

  /// Total count of unread SMS messages across all conversation threads.
  int get totalUnreadSmsCount =>
      conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  /// Total count of active mirrored notifications.
  int get activeNotificationsCount =>
      notifications.where((n) => !n.isDismissed).length;

  /// Sidebar tab label.
  String tabLabel(DesktopTab tab) {
    switch (tab) {
      case DesktopTab.devices:
        return '📱 ${strings.deviceStatus}';
      case DesktopTab.clipboard:
        return '📋 ${strings.clipboard}';
      case DesktopTab.notifications:
        final count = activeNotificationsCount;
        return count > 0
            ? '🔔 ${strings.notifications} ($count)'
            : '🔔 ${strings.notifications}';
      case DesktopTab.messages:
        final unread = totalUnreadSmsCount;
        return unread > 0
            ? '💬 ${strings.messages} ($unread)'
            : '💬 ${strings.messages}';
      case DesktopTab.files:
        return '📁 ${strings.fileTransfer}';
      case DesktopTab.screen:
        return '🖥️ ${strings.remoteControl}';
      case DesktopTab.settings:
        return '⚙️ ${strings.diagnostics}';
    }
  }

  /// Window title bar text.
  String get windowTitle {
    if (isConnected && peerDeviceName != null) {
      final battery = batteryIndicator?.displayLabel ?? '';
      return 'AndroMac — $peerDeviceName ($battery)';
    }
    return 'AndroMac — ${strings.disconnected}';
  }

  DesktopMainWindowViewConfig copyWith({
    DesktopTab? activeTab,
    bool? isConnected,
    String? peerDeviceName,
    String? peerDeviceId,
    int? batteryLevel,
    bool? isCharging,
    List<NotificationTileConfig>? notifications,
    List<SmsConversationTileConfig>? conversations,
    List<SmsMessageBubbleConfig>? activeMessages,
    String? selectedThreadId,
    List<ClipboardTileConfig>? clipboardHistory,
    List<FileTransferCardConfig>? fileTransfers,
    DiagnosticsChecklistConfig>? diagnostics,
    BridgeLocale? currentLocale,
  }) {
    return DesktopMainWindowViewConfig(
      activeTab: activeTab ?? this.activeTab,
      isConnected: isConnected ?? this.isConnected,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      notifications: notifications ?? this.notifications,
      conversations: conversations ?? this.conversations,
      activeMessages: activeMessages ?? this.activeMessages,
      selectedThreadId: selectedThreadId ?? this.selectedThreadId,
      clipboardHistory: clipboardHistory ?? this.clipboardHistory,
      fileTransfers: fileTransfers ?? this.fileTransfers,
      diagnostics: diagnostics ?? this.diagnostics,
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }

  @override
  String toString() =>
      'DesktopMainWindowView(title: $windowTitle, tab: ${activeTab.name}, notifs: $activeNotificationsCount, sms: $totalUnreadSmsCount)';
}
