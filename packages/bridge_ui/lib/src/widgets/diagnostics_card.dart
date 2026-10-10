import 'package:meta/meta.dart';

/// Single item in the system diagnostics checklist.
@immutable
class DiagnosticsItemConfig {
  final String id;
  final String title;
  final String description;
  final String status; // 'ok', 'warning', 'error', 'pending'
  final String? actionLabel;

  const DiagnosticsItemConfig({
    required this.id,
    required this.title,
    required this.description,
    this.status = 'ok',
    this.actionLabel,
  });

  /// Status icon symbol.
  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'ok':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'pending':
      default:
        return '⏳';
    }
  }

  /// Whether this check has passed successfully.
  bool get isHealthy => status == 'ok';

  @override
  String toString() => '$statusIcon $title: $description';
}

/// Overall diagnostics checklist model for troubleshooting connection and permissions.
@immutable
class DiagnosticsChecklistConfig {
  final List<DiagnosticsItemConfig> items;

  const DiagnosticsChecklistConfig({
    required this.items,
  });

  int get totalCount => items.length;

  int get healthyCount => items.where((i) => i.isHealthy).length;

  bool get allPassed => healthyCount == totalCount && totalCount > 0;

  String get summary => '$healthyCount/$totalCount проверок пройдено';

  @override
  String toString() => 'DiagnosticsChecklist($summary)';
}
