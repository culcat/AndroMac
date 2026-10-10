import 'package:meta/meta.dart';

/// Presentation configuration for an active or completed file transfer card.
@immutable
class FileTransferCardConfig {
  final String transferId;
  final String fileName;
  final int fileSizeBytes;
  final int transferredBytes;
  final bool isOutbound;
  final String state; // 'offered', 'transferring', 'completed', 'failed', 'cancelled'
  final String? errorMessage;

  const FileTransferCardConfig({
    required this.transferId,
    required this.fileName,
    required this.fileSizeBytes,
    this.transferredBytes = 0,
    required this.isOutbound,
    this.state = 'transferring',
    this.errorMessage,
  });

  /// Progress percentage [0.0 - 100.0].
  double get percentage {
    if (fileSizeBytes <= 0) return 0.0;
    final pct = (transferredBytes / fileSizeBytes) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  /// Direction label with icon.
  String get directionLabel => isOutbound ? '↗️ Отправка' : '↙️ Получение';

  /// Human-readable file size formatting.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Formatted total file size.
  String get formattedTotalSize => formatBytes(fileSizeBytes);

  /// Formatted transferred size.
  String get formattedTransferredSize => formatBytes(transferredBytes);

  /// Progress description string (e.g. "4.2 MB / 10.0 MB (42%)").
  String get progressDescription =>
      '$formattedTransferredSize / $formattedTotalSize (${percentage.toStringAsFixed(0)}%)';

  /// Whether the transfer has reached a terminal state.
  bool get isFinished =>
      state == 'completed' || state == 'failed' || state == 'cancelled';

  /// Status icon and text label.
  String get statusBadge {
    switch (state) {
      case 'completed':
        return '✅ Завершено';
      case 'failed':
        return '❌ Ошибка';
      case 'cancelled':
        return '🚫 Отменено';
      case 'offered':
        return '⏳ Ожидание согласия';
      case 'transferring':
      default:
        return '⚡ Передача (${percentage.toStringAsFixed(0)}%)';
    }
  }

  @override
  String toString() => '$directionLabel $fileName: $progressDescription [$statusBadge]';
}
