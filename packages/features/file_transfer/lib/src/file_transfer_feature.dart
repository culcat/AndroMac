import 'dart:async';
import 'dart:typed_data';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_core/bridge_core.dart';
import 'file_transfer_model.dart';
import 'file_transfer_session.dart';

/// Feature plugin coordinating chunked P2P local file transfer with SHA-256 integrity checks.
class FileTransferFeature implements BridgeFeature {
  static const String typeOffer = 'file.offer';
  static const String typeAccept = 'file.accept';
  static const String typeChunk = 'file.chunk';
  static const String typeDone = 'file.done';
  static const String typeCancel = 'file.cancel';

  @override
  final String id = 'file_transfer';

  @override
  final Set<String> incomingTypes = const <String>{
    typeOffer,
    typeAccept,
    typeChunk,
    typeDone,
    typeCancel,
  };

  final String localDeviceId;

  final StreamController<FileOffer> _offerController =
      StreamController<FileOffer>.broadcast();
  final StreamController<FileTransferProgress> _progressController =
      StreamController<FileTransferProgress>.broadcast();
  final StreamController<Uint8List> _receivedFileController =
      StreamController<Uint8List>.broadcast();

  final Map<String, IncomingTransferSession> _incomingSessions =
      <String, IncomingTransferSession>{};
  final Map<String, OutgoingTransferSession> _outgoingSessions =
      <String, OutgoingTransferSession>{};

  FeatureContext? _context;

  FileTransferFeature({required this.localDeviceId});

  /// Stream of incoming file transfer offers awaiting user acceptance.
  Stream<FileOffer> get onFileOffered => _offerController.stream;

  /// Stream of active file transfer progress updates.
  Stream<FileTransferProgress> get onProgress => _progressController.stream;

  /// Stream emitting successfully received and integrity-verified file bytes.
  Stream<Uint8List> get onFileReceived => _receivedFileController.stream;

  @override
  Future<void> start(FeatureContext ctx) async {
    _context = ctx;
  }

  @override
  Future<void> stop() async {
    _context = null;
    _incomingSessions.clear();
    _outgoingSessions.clear();
  }

  @override
  void onMessage(Envelope message) {
    switch (message.type) {
      case typeOffer:
        _handleOffer(message);
        break;
      case typeAccept:
        _handleAccept(message);
        break;
      case typeChunk:
        _handleChunk(message);
        break;
      case typeDone:
        _handleDone(message);
        break;
      case typeCancel:
        _handleCancel(message);
        break;
    }
  }

  /// Offers a local file for transfer to the connected peer.
  String? offerFile({
    required String fileName,
    required Uint8List fileBytes,
    String mimeType = 'application/octet-stream',
  }) {
    if (_context == null || !_context!.isConnected) return null;

    final transferId =
        'transfer-${DateTime.now().millisecondsSinceEpoch}-${CryptoUtils.generateNumericOtp(4)}';
    final sha256 = CryptoUtils.toHex(CryptoUtils.sha256(fileBytes));

    final offer = FileOffer(
      transferId: transferId,
      fileName: fileName,
      fileSizeBytes: fileBytes.length,
      mimeType: mimeType,
      sha256: sha256,
      senderDeviceId: localDeviceId,
    );

    final session = OutgoingTransferSession(
      offer: offer,
      fileBytes: fileBytes,
    );
    _outgoingSessions[transferId] = session;

    final envelope = Envelope.create(
      type: typeOffer,
      payload: offer.toMap(),
    );

    _context!.send(envelope);

    _progressController.add(
      FileTransferProgress(
        transferId: transferId,
        fileName: fileName,
        bytesTransferred: 0,
        totalBytes: fileBytes.length,
        state: FileTransferState.offered,
      ),
    );

    return transferId;
  }

  /// Accepts an incoming file offer, triggering chunk transmission from the sender.
  bool acceptFile(String transferId) {
    if (_context == null || !_context!.isConnected) return false;
    final session = _incomingSessions[transferId];
    if (session == null) return false;

    final envelope = Envelope.create(
      type: typeAccept,
      payload: <String, dynamic>{'transferId': transferId},
    );

    _context!.send(envelope);
    return true;
  }

  /// Rejects or cancels an ongoing file transfer.
  bool cancelTransfer(String transferId) {
    if (_context == null || !_context!.isConnected) return false;

    _incomingSessions.remove(transferId)?.cancel();
    _outgoingSessions.remove(transferId)?.cancel();

    final envelope = Envelope.create(
      type: typeCancel,
      payload: <String, dynamic>{'transferId': transferId},
    );

    _context!.send(envelope);
    return true;
  }

  void _handleOffer(Envelope message) {
    final offer = FileOffer.fromMap(message.payload);
    _incomingSessions[offer.transferId] = IncomingTransferSession(offer);
    _offerController.add(offer);
  }

  void _handleAccept(Envelope message) {
    final transferId = message.payload['transferId'] as String?;
    if (transferId == null) return;

    final session = _outgoingSessions[transferId];
    if (session == null) return;

    // Begin chunk streaming
    _streamOutgoingChunks(session);
  }

  void _streamOutgoingChunks(OutgoingTransferSession session) {
    if (_context == null || !_context!.isConnected) return;

    while (session.hasMoreChunks) {
      final chunkPayload = session.nextChunk();
      final envelope = Envelope.create(
        type: typeChunk,
        payload: chunkPayload,
      );
      _context!.send(envelope);

      final transferred = session.currentChunkIndex * session.chunkSize;
      _progressController.add(
        FileTransferProgress(
          transferId: session.offer.transferId,
          fileName: session.offer.fileName,
          bytesTransferred: (transferred < session.fileBytes.length)
              ? transferred
              : session.fileBytes.length,
          totalBytes: session.fileBytes.length,
          state: FileTransferState.transferring,
        ),
      );
    }

    // Send completion envelope
    final doneEnvelope = Envelope.create(
      type: typeDone,
      payload: <String, dynamic>{'transferId': session.offer.transferId},
    );
    _context!.send(doneEnvelope);

    _progressController.add(
      FileTransferProgress(
        transferId: session.offer.transferId,
        fileName: session.offer.fileName,
        bytesTransferred: session.fileBytes.length,
        totalBytes: session.fileBytes.length,
        state: FileTransferState.completed,
      ),
    );
  }

  void _handleChunk(Envelope message) {
    final transferId = message.payload['transferId'] as String?;
    final dataBase64 = message.payload['data'] as String?;
    if (transferId == null || dataBase64 == null) return;

    final session = _incomingSessions[transferId];
    if (session == null) return;

    session.appendChunk(dataBase64);

    _progressController.add(
      FileTransferProgress(
        transferId: transferId,
        fileName: session.offer.fileName,
        bytesTransferred: session.bytesReceived,
        totalBytes: session.offer.fileSizeBytes,
        state: FileTransferState.transferring,
      ),
    );
  }

  void _handleDone(Envelope message) {
    final transferId = message.payload['transferId'] as String?;
    if (transferId == null) return;

    final session = _incomingSessions.remove(transferId);
    if (session == null) return;

    try {
      final verifiedBytes = session.finalizeAndVerify();
      _progressController.add(
        FileTransferProgress(
          transferId: transferId,
          fileName: session.offer.fileName,
          bytesTransferred: session.offer.fileSizeBytes,
          totalBytes: session.offer.fileSizeBytes,
          state: FileTransferState.completed,
        ),
      );
      _receivedFileController.add(verifiedBytes);
    } catch (e) {
      _progressController.add(
        FileTransferProgress(
          transferId: transferId,
          fileName: session.offer.fileName,
          bytesTransferred: session.bytesReceived,
          totalBytes: session.offer.fileSizeBytes,
          state: FileTransferState.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _handleCancel(Envelope message) {
    final transferId = message.payload['transferId'] as String?;
    if (transferId == null) return;

    _incomingSessions.remove(transferId)?.cancel();
    _outgoingSessions.remove(transferId)?.cancel();

    _progressController.add(
      FileTransferProgress(
        transferId: transferId,
        fileName: 'file',
        bytesTransferred: 0,
        totalBytes: 0,
        state: FileTransferState.cancelled,
      ),
    );
  }

  void dispose() {
    _offerController.close();
    _progressController.close();
    _receivedFileController.close();
  }
}
