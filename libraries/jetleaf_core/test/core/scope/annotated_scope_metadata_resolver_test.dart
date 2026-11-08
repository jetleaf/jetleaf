import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotatedScopeMetadataResolver', () {
    final resolver = AnnotatedScopeMetadataResolver();

    test('returns singleton for class without @Scope annotation', () {
      final scope = resolver.resolve(Class<PlainClass>());
      expect(scope, equals('singleton'));
    });

    test('returns annotation value for class with @Scope', () {
      final scope = resolver.resolve(Class<PrototypeClass>());
      expect(scope, equals('prototype'));
    });

    test('resolveScopeDescriptor returns ScopeDesign.type for plain class', () {
      final design = resolver.resolveScopeDescriptor(Class<PlainClass>());
      expect(design.type, equals(ScopeType.SINGLETON.name));
    });
  });
}

class PlainClass {}

@Scope('prototype')
class PrototypeClass {}