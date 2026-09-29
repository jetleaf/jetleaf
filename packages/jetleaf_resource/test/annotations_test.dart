import 'package:test/test.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

void main() {
  group('Cacheable Annotation', () {
    test('should create with cache names', () {
      const annotation = Cacheable({'users'});
      expect(annotation.cacheNames, equals({'users'}));
    });

    test('should have default condition and unless', () {
      const annotation = Cacheable({'users'});
      expect(annotation.condition, isA<WhenAlways>());
      expect(annotation.unless, isA<WhenNever>());
    });

    test('should create with custom condition and unless', () {
      const annotation = Cacheable(
        {'users'},
        condition: WhenNever(),
        unless: WhenAlways(),
      );
      expect(annotation.condition, isA<WhenNever>());
      expect(annotation.unless, isA<WhenAlways>());
    });

    test('should create with optional parameters', () {
      const annotation = Cacheable(
        {'users'},
        ttl: Duration(minutes: 10),
        keyGenerator: 'customKeyGen',
        cacheManager: 'customManager',
        cacheResolver: 'customResolver',
      );
      expect(annotation.ttl, equals(Duration(minutes: 10)));
      expect(annotation.keyGenerator, equals('customKeyGen'));
      expect(annotation.cacheManager, equals('customManager'));
      expect(annotation.cacheResolver, equals('customResolver'));
    });

    test('should return Cacheable as annotationType', () {
      const annotation = Cacheable({'users'});
      expect(annotation.annotationType, equals(Cacheable));
    });

    test('should support multiple cache names', () {
      const annotation = Cacheable({'users', 'profiles', 'sessions'});
      expect(annotation.cacheNames.length, equals(3));
      expect(annotation.cacheNames, containsAll({'users', 'profiles', 'sessions'}));
    });
  });

  group('CachePut Annotation', () {
    test('should create with cache names', () {
      const annotation = CachePut({'users'});
      expect(annotation.cacheNames, equals({'users'}));
    });

    test('should have default condition and unless', () {
      const annotation = CachePut({'users'});
      expect(annotation.condition, isA<WhenAlways>());
      expect(annotation.unless, isA<WhenNever>());
    });

    test('should create with custom parameters', () {
      const annotation = CachePut(
        {'users'},
        ttl: Duration(seconds: 30),
        condition: WhenNever(),
        unless: WhenAlways(),
      );
      expect(annotation.ttl, equals(Duration(seconds: 30)));
      expect(annotation.condition, isA<WhenNever>());
      expect(annotation.unless, isA<WhenAlways>());
    });

    test('should return CachePut as annotationType', () {
      const annotation = CachePut({'users'});
      expect(annotation.annotationType, equals(CachePut));
    });

    test('should be a Cacheable subtype', () {
      const annotation = CachePut({'users'});
      expect(annotation, isA<Cacheable>());
    });
  });

  group('CacheEvict Annotation', () {
    test('should create with cache names', () {
      const annotation = CacheEvict({'users'});
      expect(annotation.cacheNames, equals({'users'}));
    });

    test('should have default allEntries and beforeInvocation', () {
      const annotation = CacheEvict({'users'});
      expect(annotation.allEntries, isFalse);
      expect(annotation.beforeInvocation, isFalse);
    });

    test('should create with allEntries true', () {
      const annotation = CacheEvict({'users'}, allEntries: true);
      expect(annotation.allEntries, isTrue);
    });

    test('should create with beforeInvocation true', () {
      const annotation = CacheEvict({'users'}, beforeInvocation: true);
      expect(annotation.beforeInvocation, isTrue);
    });

    test('should create with custom condition and unless', () {
      const annotation = CacheEvict(
        {'users'},
        condition: WhenNever(),
        unless: WhenAlways(),
      );
      expect(annotation.condition, isA<WhenNever>());
      expect(annotation.unless, isA<WhenAlways>());
    });

    test('should return CacheEvict as annotationType', () {
      const annotation = CacheEvict({'users'});
      expect(annotation.annotationType, equals(CacheEvict));
    });

    test('should be a Cacheable subtype', () {
      const annotation = CacheEvict({'users'});
      expect(annotation, isA<Cacheable>());
    });

    test('should support optional custom components', () {
      const annotation = CacheEvict(
        {'users'},
        keyGenerator: 'customKeyGen',
        cacheManager: 'customManager',
        cacheResolver: 'customResolver',
      );
      expect(annotation.keyGenerator, equals('customKeyGen'));
      expect(annotation.cacheManager, equals('customManager'));
      expect(annotation.cacheResolver, equals('customResolver'));
    });
  });

  group('RateLimit Annotation', () {
    test('should create with storage names, limit, and window', () {
      const annotation = RateLimit(
        {'apiStorage'},
        limit: 100,
        window: Duration(minutes: 1),
      );
      expect(annotation.storageNames, equals({'apiStorage'}));
      expect(annotation.limit, equals(100));
      expect(annotation.window, equals(Duration(minutes: 1)));
    });

    test('should have default condition and unless', () {
      const annotation = RateLimit(
        {'storage'},
        limit: 50,
        window: Duration(seconds: 30),
      );
      expect(annotation.condition, isA<WhenAlways>());
      expect(annotation.unless, isA<WhenNever>());
    });

    test('should create with custom condition and unless', () {
      const annotation = RateLimit(
        {'storage'},
        limit: 10,
        window: Duration(seconds: 10),
        condition: WhenNever(),
        unless: WhenAlways(),
      );
      expect(annotation.condition, isA<WhenNever>());
      expect(annotation.unless, isA<WhenAlways>());
    });

    test('should create with optional custom components', () {
      const annotation = RateLimit(
        {'storage'},
        limit: 100,
        window: Duration(minutes: 1),
        keyGenerator: 'customKeyGen',
        rateLimitManager: 'customManager',
        rateLimitResolver: 'customResolver',
      );
      expect(annotation.keyGenerator, equals('customKeyGen'));
      expect(annotation.rateLimitManager, equals('customManager'));
      expect(annotation.rateLimitResolver, equals('customResolver'));
    });

    test('should return RateLimit as annotationType', () {
      const annotation = RateLimit(
        {'storage'},
        limit: 100,
        window: Duration(minutes: 1),
      );
      expect(annotation.annotationType, equals(RateLimit));
    });

    test('should support multiple storage names', () {
      const annotation = RateLimit(
        {'storage1', 'storage2', 'storage3'},
        limit: 100,
        window: Duration(minutes: 1),
      );
      expect(annotation.storageNames.length, equals(3));
    });
  });
}
