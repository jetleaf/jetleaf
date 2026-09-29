import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('DefaultBootstrapContext', () {
    late DefaultBootstrapContext context;

    setUp(() {
      context = DefaultBootstrapContext();
    });

    test('should create empty context', () {
      expect(context, isNotNull);
      expect(context, isA<ConfigurableBootstrapContext>());
    });

    test('should register and check registration', () {
      final type = Class<String>();
      final supplier = BootstrapInstanceSupplier.of('test');
      context.register(type, supplier);
      expect(context.isRegistered(type), isTrue);
    });

    test('should return false for unregistered type', () {
      final type = Class<int>();
      expect(context.isRegistered(type), isFalse);
    });

    test('should get registered instance', () {
      final type = Class<String>();
      final supplier = BootstrapInstanceSupplier.of('hello');
      context.register(type, supplier);
      final result = context.get(type);
      expect(result, equals('hello'));
    });

    test('should return orElse for unregistered type', () {
      final type = Class<String>();
      final result = context.get(type, orElse: 'fallback');
      expect(result, equals('fallback'));
    });

    test('should call orSupply for unregistered type', () {
      final type = Class<String>();
      final result = context.get(type, orSupply: () => 'supplied');
      expect(result, equals('supplied'));
    });

    test('should throw for unregistered type without fallback', () {
      final type = Class<String>();
      expect(
        () => context.get(type),
        throwsA(isA<IllegalStateException>()),
      );
    });

    test('should get or throw with custom exception', () {
      final type = Class<String>();
      expect(
        () => context.getOrThrow(type, () => IllegalStateException('not found')),
        throwsA(isA<IllegalStateException>()),
      );
    });

    test('should get supplier', () {
      final type = Class<String>();
      final supplier = BootstrapInstanceSupplier.of('test');
      context.register(type, supplier);
      final result = context.getSupplier(type);
      expect(result, isNotNull);
    });

    test('should set and get application class', () {
      final appClass = Class<Object>();
      context.setApplicationClass(appClass);
      expect(context.getApplicationClass(), equals(appClass));
    });

    test('should cache singleton instances', () {
      final type = Class<String>();
      var callCount = 0;
      final supplier = BootstrapInstanceSupplier.from(() {
        callCount++;
        return 'cached';
      });
      context.register(type, supplier);
      context.get(type);
      context.get(type);
      expect(callCount, equals(1));
    });

    test('should create new instances for prototype scope', () {
      final type = Class<String>();
      var callCount = 0;
      final supplier = BootstrapInstanceSupplier.from(() {
        callCount++;
        return 'prototype';
      }).withScope(ScopeType.PROTOTYPE);
      context.register(type, supplier);
      context.get(type);
      context.get(type);
      expect(callCount, equals(2));
    });

    test('isClassRegistered should work', () {
      final type = Class<String>();
      expect(context.isClassRegistered(type), isFalse);
      context.register(type, BootstrapInstanceSupplier.of('test'));
      expect(context.isClassRegistered(type), isTrue);
    });
  });

  group('BootstrapInstanceSupplier', () {
    test('should create constant supplier', () {
      final supplier = BootstrapInstanceSupplier.of('constant');
      expect(supplier, isNotNull);
      expect(supplier.scope, equals(ScopeType.SINGLETON));
    });

    test('should return same instance from constant supplier', () {
      final supplier = BootstrapInstanceSupplier.of('constant');
      final context = DefaultBootstrapContext();
      final result1 = supplier.get(context);
      final result2 = supplier.get(context);
      expect(identical(result1, result2), isTrue);
    });

    test('should create factory supplier', () {
      final supplier = BootstrapInstanceSupplier.from(() => 'dynamic');
      expect(supplier, isNotNull);
      expect(supplier.scope, equals(ScopeType.SINGLETON));
    });

    test('should create new instance from factory supplier', () {
      var callCount = 0;
      final supplier = BootstrapInstanceSupplier.from(() {
        callCount++;
        return 'instance_$callCount';
      });
      final context = DefaultBootstrapContext();
      final result1 = supplier.get(context);
      final result2 = supplier.get(context);
      expect(result1, equals('instance_1'));
      expect(result2, equals('instance_2'));
    });

    test('should change scope with withScope', () {
      final supplier = BootstrapInstanceSupplier.of('test');
      final prototypeSupplier = supplier.withScope(ScopeType.PROTOTYPE);
      expect(prototypeSupplier.scope, equals(ScopeType.PROTOTYPE));
    });
  });
}
