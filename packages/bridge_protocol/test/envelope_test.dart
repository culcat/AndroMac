import 'dart:convert';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';

void main() {
  group('Envelope', () {
    test('create generates valid Envelope with ULID and timestamp', () {
      final envelope = Envelope.create(
        type: 'ping',
        payload: {'timestamp': 1760000000000},
      );

      expect(envelope.v, equals(Envelope.currentVersion));
      expect(envelope.id.length, equals(26));
      expect(envelope.type, equals('ping'));
      expect(envelope.ts, isPositive);
      expect(envelope.ref, isNull);
      expect(envelope.payload['timestamp'], equals(1760000000000));
    });

    test('serializes to JSON correctly', () {
      final envelope = Envelope(
        v: 1,
        id: '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        type: 'clipboard.update',
        ts: 1760000000000,
        ref: '01ARZ3NDEKTSV4RRFFQ69G5FA0',
        payload: {
          'mime': 'text/plain',
          'data': 'Hello, Mac!',
        },
      );

      final jsonMap = envelope.toJson();
      expect(jsonMap['v'], equals(1));
      expect(jsonMap['id'], equals('01ARZ3NDEKTSV4RRFFQ69G5FAV'));
      expect(jsonMap['type'], equals('clipboard.update'));
      expect(jsonMap['ts'], equals(1760000000000));
      expect(jsonMap['ref'], equals('01ARZ3NDEKTSV4RRFFQ69G5FA0'));
      expect(jsonMap['payload']['data'], equals('Hello, Mac!'));

      final encoded = envelope.encode();
      expect(encoded, isA<String>());
      expect(jsonDecode(encoded)['type'], equals('clipboard.update'));
    });

    test('deserializes from valid JSON correctly', () {
      final jsonString = jsonEncode({
        'v': 1,
        'id': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        'type': 'ping',
        'ts': 1760000000000,
        'payload': {'timestamp': 1760000000000},
      });

      final envelope = Envelope.decode(jsonString);
      expect(envelope.v, equals(1));
      expect(envelope.id, equals('01ARZ3NDEKTSV4RRFFQ69G5FAV'));
      expect(envelope.type, equals('ping'));
      expect(envelope.ts, equals(1760000000000));
      expect(envelope.ref, isNull);
      expect(envelope.payload['timestamp'], equals(1760000000000));
    });

    test('throws FormatException on malformed envelope', () {
      expect(() => Envelope.decode('{"v": "invalid"}'), throwsFormatException);
      expect(
          () => Envelope.decode('{"v": 1, "id": 123}'), throwsFormatException);
      expect(() => Envelope.decode('{"v": 1, "id": "abc"}'),
          throwsFormatException);
      expect(() => Envelope.decode('{"v": 1, "id": "abc", "type": "ping"}'),
          throwsFormatException);
    });

    test('generateUlid produces 26-character Crockford Base32 strings', () {
      final ulid1 = Envelope.generateUlid();
      final ulid2 = Envelope.generateUlid();

      expect(ulid1.length, equals(26));
      expect(ulid2.length, equals(26));
      expect(ulid1, isNot(equals(ulid2)));
    });
  });
}
