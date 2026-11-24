import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';
import '../../../lang/meta/test_data.dart' show ensureTestAotRegisteredSync;


// Test interfaces and base classes
abstract class AssignableCache {
  void put(String key, Object value);
  Object? get(String key);
}

abstract class AssignableRepository<T> {
  Future<T?> findById(String id);
}

abstract class AssignableService {}

// Test implementations
final class AssignableMemoryCache implements AssignableCache {
  @override
  void put(String key, Object value) {}
  
  @override
  Object? get(String key) => null;
}

final class AssignableUserRepository implements AssignableRepository<String> {
  @override
  Future<String?> findById(String id) async => null;
}

final class AssignableUserService implements AssignableService {}

final class PlainClass {}

@JetleafTest()
void main() {
  ensureTestAotRegisteredSync();
  group('AssignableTypeFilter', () {
    test('should match class implementing target interface', () {
      final filter = AssignableTypeFilter(Class<AssignableCache>());
      final memoryCacheClass = Class<AssignableMemoryCache>();
      final plainClass = Class<PlainClass>();

      expect(filter.matches(memoryCacheClass), isTrue);
      expect(filter.matches(plainClass), isFalse);
    });

    test('should match class implementing generic interface', () {
      final filter = AssignableTypeFilter(Class<AssignableRepository>());
      final repoClass = Class<AssignableUserRepository>();
      final plainClass = Class<PlainClass>();

      expect(filter.matches(repoClass), isTrue);
      expect(filter.matches(plainClass), isFalse);
    });

    test('should match class implementing Service', () {
      final filter = AssignableTypeFilter(Class<AssignableService>());
      final serviceClass = Class<AssignableUserService>();
      final cacheClass = Class<AssignableMemoryCache>();

      expect(filter.matches(serviceClass), isTrue);
      expect(filter.matches(cacheClass), isFalse);
    });

    test('should match same class type', () {
      final filter = AssignableTypeFilter(Class<PlainClass>());
      final plainClass = Class<PlainClass>();

      expect(filter.matches(plainClass), isTrue);
    });

    test('should not match unrelated classes', () {
      final filter = AssignableTypeFilter(Class<AssignableCache>());
      final serviceClass = Class<AssignableUserService>();
      final repoClass = Class<AssignableUserRepository>();

      expect(filter.matches(serviceClass), isFalse);
      expect(filter.matches(repoClass), isFalse);
    });
  });
}