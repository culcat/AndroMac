import 'package:meta/meta.dart';

/// Navigation tabs in the macOS desktop app.
enum DesktopTab {
  devices,
  clipboard,
  notifications,
  messages,
  files,
  screen,
  settings,
}

/// State representation for the macOS window and popover views.
@immutable
class DesktopAppViewModel {
  final DesktopTab currentTab;
  final bool isConnected;
  final String? peerName;
  final int? batteryLevel;
  final bool isCharging;
  final int activeNotificationsCount;
  final int unreadSmsCount;
  final int clipboardItemsCount;

  const DesktopAppViewModel({
    this.currentTab = DesktopTab.devices,
    this.isConnected = false,
    this.peerName,
    this.batteryLevel,
    this.isCharging = false,
    this.activeNotificationsCount = 0,
    this.unreadSmsCount = 0,
    this.clipboardItemsCount = 0,
  });

  DesktopAppViewModel copyWith({
    DesktopTab? currentTab,
    bool? isConnected,
    String? peerName,
    int? batteryLevel,
    bool? isCharging,
    int? activeNotificationsCount,
    int? unreadSmsCount,
    int? clipboardItemsCount,
  }) {
    return DesktopAppViewModel(
      currentTab: currentTab ?? this.currentTab,
      isConnected: isConnected ?? this.isConnected,
      peerName: peerName ?? this.peerName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      activeNotificationsCount:
          activeNotificationsCount ?? this.activeNotificationsCount,
      unreadSmsCount: unreadSmsCount ?? this.unreadSmsCount,
      clipboardItemsCount: clipboardItemsCount ?? this.clipboardItemsCount,
    );
  }

  @override
  String toString() =>
      'DesktopAppViewModel(tab: ${currentTab.name}, connected: $isConnected, peer: $peerName, battery: $batteryLevel%)';
}
