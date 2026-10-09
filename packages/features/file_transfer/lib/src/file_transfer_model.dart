import 'package:meta/meta.dart';

/// Lifecycle state of a file transfer.
enum FileTransferState {
  offered,
  transferring,
  completed,
  cancelled,
  failed,
}

/// Description of a file offered for transfer over the local network.
@immutable
class FileOffer {
  final String transferId;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String sha256;
  final String senderDeviceId;

  const FileOffer({
    required this.transferId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.sha256,
    required this.senderDeviceId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'transferId': transferId,
      'fileName': fileName,
      'size': fileSizeBytes,
      'mime': mimeType,
      'sha256': sha256,
      'sender': senderDeviceId,
    };
  }

  factory FileOffer.fromMap(Map<String, dynamic> map) {
    return FileOffer(
      transferId: map['transferId'] as String? ?? '',
      fileName: map['fileName'] as String? ?? 'file',
      fileSizeBytes: map['size'] as int? ?? 0,
      mimeType: map['mime'] as String? ?? 'application/octet-stream',
      sha256: map['sha256'] as String? ?? '',
      senderDeviceId: map['sender'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'FileOffer(id: $transferId, name: $fileName, size: $fileSizeBytes bytes, sha256: $sha256)';
}

/// Live progress update for an ongoing file transfer.
@immutable
class FileTransferProgress {
  final String transferId;
  final String fileName;
  final int bytesTransferred;
  final int totalBytes;
  final FileTransferState state;
  final String? errorMessage;

  const FileTransferProgress({
    required this.transferId,
    required this.fileName,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.state,
    this.errorMessage,
  });

  double get fraction => totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : 0.0;
  int get percentage => (fraction * 100).round();

  @override
  String toString() =>
      'FileTransferProgress(id: $transferId, progress: $percentage%, state: $state)';
}
