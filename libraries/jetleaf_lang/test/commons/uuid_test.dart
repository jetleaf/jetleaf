import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid', () {
    group('Construction', () {
      test('should create UUID from bits', () {
        final uuid = Uuid.fromBits(0x550e8400e29b41d4, 0xa716446655440000);
        expect(uuid.mostSignificantBits, equals(0x550e8400e29b41d4));
        expect(uuid.leastSignificantBits, equals(0xa716446655440000));
      });

      test('should create UUID from string with hyphens', () {
        final uuidString = '550e8400-e29b-41d4-a716-446655440000';
        final uuid = Uuid.fromString(uuidString);
        expect(uuid.toString(), equals(uuidString));
      });

      test('should create UUID from string without hyphens', () {
        final compactString = '550e8400e29b41d4a716446655440000';
        final uuid = Uuid.fromString(compactString);
        expect(uuid.toCompactString(), equals(compactString));
      });

      test('should handle mixed case UUID strings', () {
        final mixedCase = '550E8400-E29B-41D4-A716-446655440000';
        final uuid = Uuid.fromString(mixedCase);
        expect(uuid.toString(), equals('550e8400-e29b-41d4-a716-446655440000'));
      });

      test('should throw FormatException for invalid UUID strings', () {
        expect(() => Uuid.fromString(''), throwsA(isA<InvalidFormatException>()));
        expect(() => Uuid.fromString('invalid'), throwsA(isA<InvalidFormatException>()));
        expect(() => Uuid.fromString('550e8400-e29b-41d4-a716'), throwsA(isA<InvalidFormatException>()));
        expect(() => Uuid.fromString('550e8400-e29b-41d4-a716-44665544000g'), throwsA(isA<InvalidFormatException>()));
      });
    });

    group('Random UUID Generation', () {
      test('should generate version 4 UUIDs', () {
        final uuid = Uuid.randomUuid();
        expect(uuid.version, equals(4));
        expect(uuid.variant, equals(2));
      });

      test('should generate unique UUIDs', () {
        final uuid1 = Uuid.randomUuid();
        final uuid2 = Uuid.randomUuid();
        expect(uuid1, isNot(equals(uuid2)));
      });

      test('should generate UUIDs with proper format', () {
        final uuid = Uuid.randomUuid();
        final uuidString = uuid.toString();
        expect(uuidString, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      });

      test('should generate many unique UUIDs', () {
        final uuids = <Uuid>{};
        for (int i = 0; i < 1000; i++) {
          uuids.add(Uuid.randomUuid());
        }
        expect(uuids.length, equals(1000));
      });
    });

    group('Time-based UUID Generation', () {
      test('should generate version 1 UUIDs', () {
        final uuid = Uuid.timeBasedUuid();
        expect(uuid.version, equals(1));
        expect(uuid.variant, equals(2));
      });

      test('should generate UUIDs with increasing timestamps', () async {
        final uuid1 = Uuid.timeBasedUuid();
        // Wait to ensure a different timestamp
        await Future.delayed(Duration(milliseconds: 2));
        final uuid2 = Uuid.timeBasedUuid();
        expect(uuid1.compareTo(uuid2), lessThan(0));
      });

      test('should provide timestamp access for version 1 UUIDs', () {
        final uuid = Uuid.timeBasedUuid();
        expect(() => uuid.timestamp, returnsNormally);
        expect(() => uuid.clockSequence, returnsNormally);
        expect(() => uuid.node, returnsNormally);
      });

      test('should throw for timestamp access on non-version-1 UUIDs', () {
        final uuid = Uuid.randomUuid();
        expect(() => uuid.timestamp, throwsUnsupportedError);
        expect(() => uuid.clockSequence, throwsUnsupportedError);
        expect(() => uuid.node, throwsUnsupportedError);
      });
    });

    group('Name-based UUID Generation', () {
      test('should generate version 5 UUIDs from bytes', () {
        final namespace = Uuid.NAMESPACE_DNS;
        final nameBytes = Closeable.DEFAULT_ENCODING.encode('example.com');
        final uuid = Uuid.nameUuidFromBytes(namespace, nameBytes);
        expect(uuid.version, equals(5));
        expect(uuid.variant, equals(2));
      });

      test('should generate version 5 UUIDs from strings', () {
        final uuid = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
        expect(uuid.version, equals(5));
        expect(uuid.variant, equals(2));
      });

      test('should generate deterministic UUIDs', () {
        final uuid1 = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
        final uuid2 = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
        expect(uuid1, equals(uuid2));
      });

      test('should generate different UUIDs for different names', () {
        final uuid1 = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
        final uuid2 = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'test.com');
        expect(uuid1, isNot(equals(uuid2)));
      });

      test('should generate different UUIDs for different namespaces', () {
        final uuid1 = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, 'example.com');
        final uuid2 = Uuid.nameUuidFromString(Uuid.NAMESPACE_URL, 'example.com');
        expect(uuid1, isNot(equals(uuid2)));
      });
    });

    group('Validation', () {
      test('should validate correct UUID strings', () {
        expect(Uuid.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
        expect(Uuid.isValidUuid('550e8400e29b41d4a716446655440000'), isTrue);
        expect(Uuid.isValidUuid('550E8400-E29B-41D4-A716-446655440000'), isTrue);
      });

      test('should reject invalid UUID strings', () {
        expect(Uuid.isValidUuid(''), isFalse);
        expect(Uuid.isValidUuid('invalid'), isFalse);
        expect(Uuid.isValidUuid('550e8400-e29b-41d4-a716'), isFalse);
        expect(Uuid.isValidUuid('550e8400-e29b-41d4-a716-44665544000g'), isFalse);
        expect(Uuid.isValidUuid('550e8400-e29b-41d4-a716-4466554400000'), isFalse);
      });
    });

    group('Comparison and Equality', () {
      test('should compare UUIDs correctly', () {
        final uuid1 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
        final uuid2 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440001');
        final uuid3 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');

        expect(uuid1.compareTo(uuid2), lessThan(0));
        expect(uuid2.compareTo(uuid1), greaterThan(0));
        expect(uuid1.compareTo(uuid3), equals(0));
      });

      test('should test equality correctly', () {
        final uuid1 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
        final uuid2 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
        final uuid3 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440001');

        expect(uuid1, equals(uuid2));
        expect(uuid1, isNot(equals(uuid3)));
        expect(uuid1.hashCode, equals(uuid2.hashCode));
      });

      test('should handle identical references', () {
        final uuid = Uuid.randomUuid();
        expect(uuid, equals(uuid));
        expect(uuid.compareTo(uuid), equals(0));
      });
    });

    group('Byte Conversion', () {
      test('should convert to and from bytes', () {
        final original = Uuid.randomUuid();
        final bytes = original.toBytes();
        expect(bytes.length, equals(16));
      });

      test('should handle byte array conversion correctly', () {
        final uuid = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
        final bytes = uuid.toBytes();
        
        final expected = Uint8List.fromList([
          0x55, 0x0e, 0x84, 0x00, 0xe2, 0x9b, 0x41, 0xd4,
          0xa7, 0x16, 0x44, 0x66, 0x55, 0x44, 0x00, 0x00
        ]);
        
        expect(bytes, equals(expected));
      });
    });

    group('String Representation', () {
      test('should format UUID strings correctly', () {
        final uuid = Uuid.fromBits(0x550e8400e29b41d4, 0xa716446655440000);
        expect(uuid.toString(), equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(uuid.toCompactString(), equals('550e8400e29b41d4a716446655440000'));
      });

      test('should always use lowercase in string representation', () {
        final uuid = Uuid.fromString('550E8400-E29B-41D4-A716-446655440000');
        expect(uuid.toString(), equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(uuid.toCompactString(), equals('550e8400e29b41d4a716446655440000'));
      });
    });

    group('Predefined Namespaces', () {
      test('should provide standard namespace UUIDs', () {
        expect(Uuid.NAMESPACE_DNS.toString(), equals('6ba7b810-9dad-11d1-80b4-00c04fd430c8'));
        expect(Uuid.NAMESPACE_URL.toString(), equals('6ba7b811-9dad-11d1-80b4-00c04fd430c8'));
        expect(Uuid.NAMESPACE_OID.toString(), equals('6ba7b812-9dad-11d1-80b4-00c04fd430c8'));
        expect(Uuid.NAMESPACE_X500.toString(), equals('6ba7b814-9dad-11d1-80b4-00c04fd430c8'));
      });

      test('should have correct version and variant for namespaces', () {
        expect(Uuid.NAMESPACE_DNS.version, equals(1));
        expect(Uuid.NAMESPACE_DNS.variant, equals(2));
      });
    });

    group('Edge Cases', () {
      test('should handle zero UUID', () {
        final uuid = Uuid.fromBits(0, 0);
        expect(uuid.toString(), equals('00000000-0000-0000-0000-000000000000'));
      });

      test('should handle maximum UUID', () {
        final uuid = Uuid.fromBits(-1, -1);
        expect(uuid.toString(), equals('ffffffff-ffff-ffff-ffff-ffffffffffff'));
      });

      test('should handle empty name for name-based UUIDs', () {
        final uuid = Uuid.nameUuidFromString(Uuid.NAMESPACE_DNS, '');
        expect(uuid.version, equals(5));
      });
    });

    group('Performance', () {
      test('should generate UUIDs quickly', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10000; i++) {
          Uuid.randomUuid();
        }
        stopwatch.stop();
        
        // Should generate 10,000 UUIDs in less than 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should parse UUIDs quickly', () {
        final uuidStrings = List.generate(1000, (_) => Uuid.randomUuid().toString());
        
        final stopwatch = Stopwatch()..start();
        for (final uuidString in uuidStrings) {
          Uuid.fromString(uuidString);
        }
        stopwatch.stop();
        
        // Should parse 1,000 UUIDs in less than 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}