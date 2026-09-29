import 'package:jetleaf_env/env.dart';
import 'package:test/test.dart';

void main() {
  group('Profiles', () {
    test('simple profile matches active profiles', () {
      final profiles = Profiles.of(['dev']);
      expect(profiles.matches((p) => ['dev', 'local'].contains(p)), isTrue);
    });

    test('simple profile does not match inactive profiles', () {
      final profiles = Profiles.of(['prod']);
      expect(profiles.matches((p) => ['dev', 'local'].contains(p)), isFalse);
    });

    test('NOT expression inverts match', () {
      final profiles = Profiles.of(['!prod']);
      expect(profiles.matches((p) => ['dev', 'local'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['prod'].contains(p)), isFalse);
    });

    test('AND expression requires both profiles', () {
      final profiles = Profiles.of(['dev & local']);
      expect(profiles.matches((p) => ['dev', 'local'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['dev'].contains(p)), isFalse);
    });

    test('OR expression requires at least one profile', () {
      final profiles = Profiles.of(['dev | prod']);
      expect(profiles.matches((p) => ['dev'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['prod'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['staging'].contains(p)), isFalse);
    });

    test('parentheses in expressions', () {
      final profiles = Profiles.of(['(dev | prod) & !test']);
      expect(profiles.matches((p) => ['dev'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['prod'].contains(p)), isTrue);
      expect(profiles.matches((p) => ['test'].contains(p)), isFalse);
      expect(profiles.matches((p) => ['dev', 'test'].contains(p)), isFalse);
    });

    test('empty active profiles never matches', () {
      final profiles = Profiles.of(['dev']);
      expect(profiles.matches((p) => [].contains(p)), isFalse);
    });
  });
}