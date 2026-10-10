import 'dart:convert';
import 'dart:typed_data';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'file_transfer_model.dart';

/// Manages assembly and integrity verification of an incoming file transfer.
class IncomingTransferSession {
  final FileOffer offer;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  int _bytesReceived = 0;
  bool _isCancelled = false;

  IncomingTransferSession(this.offer);

  int get bytesReceived => _bytesReceived;
  bool get isCancelled => _isCancelled;

  /// Appends a received chunk encoded as Base64.
  void appendChunk(String dataBase64) {
    if (_isCancelled) return;
    final bytes = base64Decode(dataBase64);
    _builder.add(bytes);
    _bytesReceived += bytes.length;
  }

  /// Verifies SHA-256 digest against the original offer.
  ///
  /// Returns the complete file bytes if verification succeeds.
  /// Throws [FormatException] if the digest does not match.
  Uint8List finalizeAndVerify() {
    if (_isCancelled) {
      throw StateError('Transfer session was cancelled');
    }

    final assembledBytes = _builder.takeBytes();
    final computedDigest =
        CryptoUtils.toHex(CryptoUtils.sha256(assembledBytes));

    if (!CryptoUtils.fixedTimeEquals(computedDigest, offer.sha256)) {
      throw FormatException(
        'File integrity check failed: expected ${offer.sha256}, got $computedDigest',
      );
    }

    return assembledBytes;
  }

  void cancel() {
    _isCancelled = true;
    _builder.clear();
  }
}

/// Slices an outgoing file into manageable chunks for streaming.
class OutgoingTransferSession {
  static const int defaultChunkSize = 64 * 1024; // 64 KiB chunks

  final FileOffer offer;
  final Uint8List fileBytes;
  final int chunkSize;
  final int totalChunks;

  int _currentChunkIndex = 0;
  bool _isCancelled = false;

  OutgoingTransferSession({
    required this.offer,
    required this.fileBytes,
    this.chunkSize = defaultChunkSize,
  }) : totalChunks = (fileBytes.isEmpty)
            ? 1
            : (fileBytes.length /
                    (chunkSize <= 0 ? defaultChunkSize : chunkSize))
                .ceil();

  bool get hasMoreChunks => !_isCancelled && _currentChunkIndex < totalChunks;
  bool get isCancelled => _isCancelled;
  int get currentChunkIndex => _currentChunkIndex;

  /// Retrieves the next chunk formatted as Base64 string.
  Map<String, dynamic> nextChunk() {
    if (!hasMoreChunks) {
      throw StateError('No more chunks available in session');
    }

    final start = _currentChunkIndex * chunkSize;
    final end = (start + chunkSize < fileBytes.length)
        ? start + chunkSize
        : fileBytes.length;
    final slice = fileBytes.sublist(start, end);

    final payload = <String, dynamic>{
      'transferId': offer.transferId,
      'chunkIndex': _currentChunkIndex,
      'totalChunks': totalChunks,
      'data': base64Encode(slice),
    };

    _currentChunkIndex++;
    return payload;
  }

  void cancel() {
    _isCancelled = true;
  }
}
