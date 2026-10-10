import 'package:bridge_protocol/bridge_protocol.dart';

/// Configurable rules for filtering out unwanted or system-internal notifications.
class NotificationFilter {
  /// Default system package names to exclude from mirroring to avoid noise.
  static const Set<String> defaultBlacklist = {
    'android',
    'com.android.systemui',
    'com.google.android.googlequicksearchbox',
    'com.android.providers.downloads',
  };

  final Set<String> _blockedPackages = <String>{};
  bool _filterOngoing = true;

  NotificationFilter({
    Set<String>? initialBlockedPackages,
    bool filterOngoing = true,
  }) : _filterOngoing = filterOngoing {
    _blockedPackages.addAll(defaultBlacklist);
    if (initialBlockedPackages != null) {
      _blockedPackages.addAll(initialBlockedPackages);
    }
  }

  /// Blocks mirroring from [packageName].
  void blockPackage(String packageName) {
    _blockedPackages.add(packageName.toLowerCase());
  }

  /// Unblocks mirroring from [packageName].
  void unblockPackage(String packageName) {
    _blockedPackages.remove(packageName.toLowerCase());
  }

  /// Returns true if [packageName] is currently muted/blocked.
  bool isBlocked(String packageName) =>
      _blockedPackages.contains(packageName.toLowerCase());

  /// Returns true if [packageName] should be filtered out / dropped.
  bool shouldFilter(String packageName, {bool isOngoing = false}) {
    if (_filterOngoing && isOngoing) return true;
    return isBlocked(packageName);
  }

  /// Evaluates whether a notification should be mirrored to Mac.
  bool shouldMirror(NotificationPostedPayload payload) {
    final pkg = payload.packageName.toLowerCase();

    // Check package blacklist
    if (_blockedPackages.contains(pkg)) {
      return false;
    }

    // Ignore empty content
    if (payload.title.trim().isEmpty && payload.text.trim().isEmpty) {
      return false;
    }

    return true;
  }
}
