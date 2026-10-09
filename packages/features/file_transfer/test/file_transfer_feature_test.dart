import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:file_transfer_feature/file_transfer_feature.dart';

class MockTransportChannel implements TransportChannel {
  final _incoming = StreamController<Envelope>.broadcast();
  final List<Envelope> sent = <Envelope>[];
  bool _open = true;

  @override
  Stream<Envelope> get incoming => _incoming.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    sent.add(envelope);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
  }
}

void main() {
  group('FileTransferFeature', () {
    test('offerFile calculates SHA-256 and sends file.offer envelope', () async {
      final feature = FileTransferFeature(localDeviceId: 'mac-1');
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final fileData = Uint8List.fromList(utf8.encode('Hello, andromac file transfer!'));
      final expectedSha = CryptoUtils.toHex(CryptoUtils.sha256(fileData));

      final transferId = feature.offerFile(
        fileName: 'hello.txt',
        fileBytes: fileData,
        mimeType: 'text/plain',
      );

      expect(transferId, isNotNull);
      expect(channel.sent.length, equals(1));

      final offerEnvelope = channel.sent.first;
      expect(offerEnvelope.type, equals(FileTransferFeature.typeOffer));
      final offerPayload = FileOffer.fromMap(offerEnvelope.payload);
      expect(offerPayload.fileName, equals('hello.txt'));
      expect(offerPayload.fileSizeBytes, equals(fileData.length));
      expect(offerPayload.sha256, equals(expectedSha));
    });

    test('accepting file streams chunks and verifies SHA-256 integrity on completion', () async {
      final senderFeature = FileTransferFeature(localDeviceId: 'sender-device');
      final senderChannel = MockTransportChannel();
      final senderContext = FeatureContext(peerDeviceId: 'receiver-device', channel: senderChannel);
      await senderFeature.start(senderContext);

      final receiverFeature = FileTransferFeature(localDeviceId: 'receiver-device');
      final receiverChannel = MockTransportChannel();
      final receiverContext = FeatureContext(peerDeviceId: 'sender-device', channel: receiverChannel);
      await receiverFeature.start(receiverContext);

      final fileBytes = Uint8List.fromList(utf8.encode('Top secret document content for transfer.'));

      // 1. Sender offers file
      final transferId = senderFeature.offerFile(
        fileName: 'secret.doc',
        fileBytes: fileBytes,
      );

      // 2. Deliver offer to receiver
      final offerEnvelope = senderChannel.sent.first;
      receiverFeature.onMessage(offerEnvelope);

      // 3. Receiver accepts file
      receiverFeature.acceptFile(transferId!);
      expect(receiverChannel.sent.length, equals(1));
      final acceptEnvelope = receiverChannel.sent.first;

      // 4. Deliver acceptance back to sender
      senderFeature.onMessage(acceptEnvelope);

      // 5. Sender should now have transmitted chunk(s) and done envelope
      final chunkEnvelopes = senderChannel.sent.where((e) => e.type == FileTransferFeature.typeChunk).toList();
      final doneEnvelope = senderChannel.sent.firstWhere((e) => e.type == FileTransferFeature.typeDone);

      expect(chunkEnvelopes, isNotEmpty);
      expect(doneEnvelope, isNotNull);

      // 6. Deliver chunks and done envelope to receiver
      final receivedBytesCompleter = Completer<Uint8List>();
      receiverFeature.onFileReceived.listen(receivedBytesCompleter.complete);

      for (final chunk in chunkEnvelopes) {
        receiverFeature.onMessage(chunk);
      }
      receiverFeature.onMessage(doneEnvelope);

      final result = await receivedBytesCompleter.future.timeout(const Duration(seconds: 2));
      expect(utf8.decode(result), equals('Top secret document content for transfer.'));
    });

    test('tampered chunk fails SHA-256 verification cleanly', () async {
      final receiverFeature = FileTransferFeature(localDeviceId: 'receiver-device');
      final receiverChannel = MockTransportChannel();
      final receiverContext = FeatureContext(peerDeviceId: 'sender-device', channel: receiverChannel);
      await receiverFeature.start(receiverContext);

      final progressEvents = <FileTransferProgress>[];
      receiverFeature.onProgress.listen(progressEvents.add);

      // Create fake offer
      final originalData = Uint8List.fromList(utf8.encode('Original'));
      final originalSha = CryptoUtils.toHex(CryptoUtils.sha256(originalData));

      final offerEnvelope = Envelope.create(
        type: FileTransferFeature.typeOffer,
        payload: FileOffer(
          transferId: 'transfer-tamper-1',
          fileName: 'test.bin',
          fileSizeBytes: 8,
          mimeType: 'text/plain',
          sha256: originalSha,
          senderDeviceId: 'sender-1',
        ).toMap(),
      );
      receiverFeature.onMessage(offerEnvelope);

      // Deliver tampered chunk data
      final tamperedBytes = Uint8List.fromList(utf8.encode('Tampered'));
      final chunkEnvelope = Envelope.create(
        type: FileTransferFeature.typeChunk,
        payload: {
          'transferId': 'transfer-tamper-1',
          'chunkIndex': 0,
          'totalChunks': 1,
          'data': base64Encode(tamperedBytes),
        },
      );
      receiverFeature.onMessage(chunkEnvelope);

      // Deliver done
      final doneEnvelope = Envelope.create(
        type: FileTransferFeature.typeDone,
        payload: {'transferId': 'transfer-tamper-1'},
      );
      receiverFeature.onMessage(doneEnvelope);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Should have reported failed state
      final lastProgress = progressEvents.last;
      expect(lastProgress.state, equals(FileTransferState.failed));
      expect(lastProgress.errorMessage, contains('integrity check failed'));
    });
  });
}
