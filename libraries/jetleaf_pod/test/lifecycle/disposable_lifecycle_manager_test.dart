// test/disposable_lifecycle_manager_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/lifecycle/lifecycle.dart';
import 'package:jetleaf_pod/src/lifecycle/pod_processors.dart';
import 'package:test/test.dart';
import 'package:jetleaf_pod/src/lifecycle/disposable_lifecycle_manager.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';

class TestDisposablePod implements DisposablePod {
  bool destroyed = false;

  @override
  Future<void> onDestroy() async {
    destroyed = true;
  }

  @override
  String getPackageName() => 'test.package';
}

class TestAutoCloseable implements Closeable {
  bool closed = false;

  @override
  void close() {
    closed = true;
  }
}

class TestBoth implements DisposablePod, Closeable {
  bool destroyed = false;
  bool closed = false;

  @override
  Future<void> onDestroy() async {
    destroyed = true;
  }

  @override
  void close() {
    closed = true;
  }

  @override
  String getPackageName() => 'test.package';
}

class MockPodDestructionProcessor extends PodDestructionProcessor {
  bool beforeCalled = false;
  bool afterCalled = false;
  bool requiresCalled = false;

  @override
  Future<void> processBeforeDestruction(
    Object pod,
    Class podClass,
    String podName,
  ) async {
    beforeCalled = true;
  }

  @override
  Future<void> processAfterDestruction(
    Object pod,
    Class podClass,
    String podName,
  ) async {
    afterCalled = true;
  }

  @override
  Future<bool> requiresDestruction(
    Object pod,
    Class podClass,
    String podName,
  ) async {
    requiresCalled = true;
    return true;
  }
}

@JetleafTest()
void main() {
  group('DisposableLifecycleManager', () {
    test('should create with disposable pod', () {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(manager, isA<DisposableLifecycleManager>());
      expect(manager, isA<DisposablePod>());
      expect(manager, isA<Runnable>());
    });

    test('should create with auto closeable pod', () {
      final pod = TestAutoCloseable();
      final definition = RootPodDefinition(type: Class<TestAutoCloseable>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(manager, isA<DisposableLifecycleManager>());
    });

    test('onDestroy should call disposable pod method', () async {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(pod.destroyed, isFalse);
      await manager.onDestroy();
      expect(pod.destroyed, isTrue);
    });

    test('onDestroy should call auto closeable method', () async {
      final pod = TestAutoCloseable();
      final definition = RootPodDefinition(type: Class<TestAutoCloseable>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(pod.closed, isFalse);
      await manager.onDestroy();
      expect(pod.closed, isTrue);
    });

    test(
      'onDestroy should call both methods when pod implements both',
      () async {
        final pod = TestBoth();
        final definition = RootPodDefinition(type: Class<TestBoth>());
        final manager = DisposableLifecycleManager(pod, 'test', definition, []);

        expect(pod.destroyed, isFalse);
        expect(pod.closed, isFalse);
        await manager.onDestroy();
        expect(pod.destroyed, isTrue);
        expect(pod.closed, isTrue);
      },
    );

    test('run method should call onDestroy', () {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(pod.destroyed, isFalse);
      manager.run();
      expect(pod.destroyed, isTrue);
    });

    test('should call processors before and after destruction', () async {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final processor = MockPodDestructionProcessor();
      final manager = DisposableLifecycleManager(pod, 'test', definition, [
        processor,
      ]);

      expect(processor.beforeCalled, isFalse);
      expect(processor.afterCalled, isFalse);
      await manager.onDestroy();
      expect(processor.beforeCalled, isTrue);
      expect(processor.afterCalled, isTrue);
    });

    test('getPackageName should return correct package', () {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final manager = DisposableLifecycleManager(pod, 'test', definition, []);

      expect(manager.getPackageName(), equals('jetleaf_pod'));
    });

    test('hasDestroyMethod should work for disposable pods', () {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());

      expect(
        DisposableLifecycleManager.hasDestroyMethod(pod, definition),
        isTrue,
      );
    });

    test('hasDestroyMethod should work for auto closeable pods', () {
      final pod = TestAutoCloseable();
      final definition = RootPodDefinition(type: Class<TestAutoCloseable>());

      expect(
        DisposableLifecycleManager.hasDestroyMethod(pod, definition),
        isTrue,
      );
    });

    test(
      'hasApplicableProcessors should return true when processors exist',
      () async {
        final pod = TestDisposablePod();
        final definition = RootPodDefinition(type: Class<TestDisposablePod>());
        final processor = MockPodDestructionProcessor();

        final result = await DisposableLifecycleManager.hasApplicableProcessors(
          pod,
          definition,
          {processor},
        );
        expect(result, isTrue);
      },
    );

    test('filterPostProcessors should filter processors', () async {
      final pod = TestDisposablePod();
      final definition = RootPodDefinition(type: Class<TestDisposablePod>());
      final processor = MockPodDestructionProcessor();

      final filtered = await DisposableLifecycleManager.filterPostProcessors(
        {processor},
        pod,
        definition,
      );
      expect(filtered.length, equals(1));
      expect(filtered[0], equals(processor));
    });
  });
}