import 'package:test/test.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

void main() {
  group('WhenMatching enum', () {
    test('should have all expected values', () {
      expect(WhenMatching.values.length, equals(7));
      expect(WhenMatching.values, contains(WhenMatching.EQUALS));
      expect(WhenMatching.values, contains(WhenMatching.NOT_EQUALS));
      expect(WhenMatching.values, contains(WhenMatching.EQUALS_IGNORE_CASE));
      expect(WhenMatching.values, contains(WhenMatching.NOT_EQUALS_IGNORE_CASE));
      expect(WhenMatching.values, contains(WhenMatching.EXISTS));
      expect(WhenMatching.values, contains(WhenMatching.NOT_EXISTS));
      expect(WhenMatching.values, contains(WhenMatching.REGEX));
    });
  });

  group('CacheException', () {
    test('should create with message', () {
      final exception = CacheException('test error');
      expect(exception.message, equals('test error'));
    });

    test('should create with cause', () {
      final cause = Exception('root cause');
      final exception = CacheException('test error', cause: cause);
      expect(exception.getCause(), equals(cause));
    });
  });

  group('NoCacheFoundException', () {
    test('should create with key', () {
      final exception = NoCacheFoundException('myKey');
      expect(exception.key, equals('myKey'));
    });

    test('should have default message containing key', () {
      final exception = NoCacheFoundException('myKey');
      expect(exception.message, contains('myKey'));
    });

    test('should have custom message', () {
      final exception = NoCacheFoundException('myKey', message: 'Custom message');
      expect(exception.message, equals('Custom message'));
    });

    test('should be a CacheException', () {
      final exception = NoCacheFoundException('myKey');
      expect(exception, isA<CacheException>());
    });

    test('should have toString with key', () {
      final exception = NoCacheFoundException('myKey');
      expect(exception.toString(), contains('myKey'));
    });
  });

  group('NoRateLimitFoundException', () {
    test('should create with name', () {
      final exception = NoRateLimitFoundException('apiLimit');
      expect(exception.name, equals('apiLimit'));
    });

    test('should have default message containing name', () {
      final exception = NoRateLimitFoundException('apiLimit');
      expect(exception.message, contains('apiLimit'));
    });

    test('should create with named factory', () {
      final exception = NoRateLimitFoundException.named('apiLimit');
      expect(exception.name, equals('apiLimit'));
    });

    test('should be a RuntimeException', () {
      final exception = NoRateLimitFoundException('apiLimit');
      expect(exception, isA<RuntimeException>());
    });

    test('should have toString with name', () {
      final exception = NoRateLimitFoundException('apiLimit');
      expect(exception.toString(), contains('apiLimit'));
    });
  });

  group('CacheCapacityExceededException', () {
    test('should create with cacheName and maxEntries', () {
      final exception = CacheCapacityExceededException('users', 100);
      expect(exception.cacheName, equals('users'));
      expect(exception.maxEntries, equals(100));
    });

    test('should have message containing cache name and max entries', () {
      final exception = CacheCapacityExceededException('users', 100);
      expect(exception.message, contains('users'));
      expect(exception.message, contains('100'));
    });

    test('should be a CacheException', () {
      final exception = CacheCapacityExceededException('users', 100);
      expect(exception, isA<CacheException>());
    });
  });

  group('WhenAlways', () {
    test('should always return true', () async {
      final condition = WhenAlways();
      final result = condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });
  });

  group('WhenNever', () {
    test('should always return false', () async {
      final condition = WhenNever();
      final result = condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });
  });

  group('WhenAll', () {
    test('should return true when both conditions are true', () async {
      final condition = WhenAll(WhenAlways(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });

    test('should return false when left condition is false', () async {
      final condition = WhenAll(WhenNever(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });

    test('should return false when right condition is false', () async {
      final condition = WhenAll(WhenAlways(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });

    test('should return false when both conditions are false', () async {
      final condition = WhenAll(WhenNever(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });
  });

  group('WhenAny', () {
    test('should return true when left condition is true', () async {
      final condition = WhenAny(WhenAlways(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });

    test('should return true when right condition is true', () async {
      final condition = WhenAny(WhenNever(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });

    test('should return true when both conditions are true', () async {
      final condition = WhenAny(WhenAlways(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });

    test('should return false when both conditions are false', () async {
      final condition = WhenAny(WhenNever(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });
  });

  group('WhenNot', () {
    test('should negate true to false', () async {
      final condition = WhenNot(WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });

    test('should negate false to true', () async {
      final condition = WhenNot(WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });
  });

  group('WhenNone', () {
    test('should return true when both conditions are false', () async {
      final condition = WhenNone(WhenNever(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isTrue);
    });

    test('should return false when left condition is true', () async {
      final condition = WhenNone(WhenAlways(), WhenNever());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });

    test('should return false when right condition is true', () async {
      final condition = WhenNone(WhenNever(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });

    test('should return false when both conditions are true', () async {
      final condition = WhenNone(WhenAlways(), WhenAlways());
      final result = await condition.shouldApply(_MockOperationContext());
      expect(result, isFalse);
    });
  });

  group('WhenEnv', () {
    test('should have toString representation', () {
      final condition = WhenEnv('APP_ENV', match: WhenMatching.EXISTS);
      expect(condition.toString(), contains('APP_ENV'));
      expect(condition.toString(), contains('EXISTS'));
    });
  });
}

class _MockOperationContext implements OperationContext {
  @override
  Environment getEnvironment() => throw UnimplementedError();

  @override
  Method getMethod() => throw UnimplementedError();

  @override
  ExecutableArgument? getArgument() => throw UnimplementedError();

  @override
  Object getTarget() => throw UnimplementedError();

  @override
  List<Resource<dynamic, dynamic>> getResources() => throw UnimplementedError();

  @override
  ConfigurableListablePodFactory getPodFactory() => throw UnimplementedError();
}
