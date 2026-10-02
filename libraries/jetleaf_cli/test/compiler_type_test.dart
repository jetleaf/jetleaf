import 'package:jetleaf_cli/src/common/compiler_type.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('CompilerType', () {
    test('should have JIT value', () {
      expect(CompilerType.JIT, isNotNull);
    });

    test('should have AOT value', () {
      expect(CompilerType.AOT, isNotNull);
    });

    test('should have EXE value', () {
      expect(CompilerType.EXE, isNotNull);
    });

    test('should have exactly 3 values', () {
      expect(CompilerType.values.length, equals(3));
    });

    test('should parse JIT from string', () {
      expect(CompilerType.fromString('JIT'), equals(CompilerType.JIT));
    });

    test('should parse AOT from string', () {
      expect(CompilerType.fromString('AOT'), equals(CompilerType.AOT));
    });

    test('should parse EXE from string', () {
      expect(CompilerType.fromString('EXE'), equals(CompilerType.EXE));
    });

    test('should throw on invalid string', () {
      expect(
        () => CompilerType.fromString('INVALID'),
        throwsA(isA<UnsupportedOperationException>()),
      );
    });

    test('should throw on empty string', () {
      expect(
        () => CompilerType.fromString(''),
        throwsA(isA<UnsupportedOperationException>()),
      );
    });

    test('should be case sensitive', () {
      expect(
        () => CompilerType.fromString('jit'),
        throwsA(isA<UnsupportedOperationException>()),
      );
    });
  });
}
