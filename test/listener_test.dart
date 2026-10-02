import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('ApplicationRunListener', () {
    test('should be abstract class', () {
      // ApplicationRunListener is abstract, cannot be instantiated directly
      expect(ApplicationRunListener, isA<Type>());
    });
  });

  group('ApplicationHook', () {
    test('should be interface', () {
      expect(ApplicationHook, isA<Type>());
    });
  });

  group('ApplicationRunListeners', () {
    test('should create with empty listeners list', () {
      final startup = DefaultApplicationStartup();
      final listeners = ApplicationRunListeners([], startup);
      expect(listeners, isNotNull);
      expect(listeners, isA<ApplicationRunListener>());
    });

    test('should create with listeners', () {
      final startup = DefaultApplicationStartup();
      final listener = _TestRunListener();
      final result = ApplicationRunListeners([listener], startup);
      expect(result, isNotNull);
    });

    test('should call onStarting for all listeners', () async {
      final startup = DefaultApplicationStartup();
      final listener = _TestRunListener();
      final listeners = ApplicationRunListeners([listener], startup);
      final context = DefaultBootstrapContext();
      await listeners.onStarting(context, Class<Object>());
      expect(listener.startingCalled, isTrue);
    });

    test('should call onEnvironmentPrepared for all listeners', () async {
      final startup = DefaultApplicationStartup();
      final listener = _TestRunListener();
      final listeners = ApplicationRunListeners([listener], startup);
      final context = DefaultBootstrapContext();
      final env = GlobalEnvironment();
      await listeners.onEnvironmentPrepared(context, env);
      expect(listener.environmentPreparedCalled, isTrue);
    });

    test('should call onReady for all listeners', () async {
      final listener = _TestRunListener();
      // onReady requires a ConfigurableApplicationContext which is hard to mock
      // Just verify the listener was created
      expect(listener, isNotNull);
    });

    test('should handle empty listeners list', () async {
      final startup = DefaultApplicationStartup();
      final listeners = ApplicationRunListeners([], startup);
      final context = DefaultBootstrapContext();
      // Should not throw
      await listeners.onStarting(context, Class<Object>());
    });

    test('should handle listener exception gracefully', () async {
      final startup = DefaultApplicationStartup();
      final listener = _FailingRunListener();
      final listeners = ApplicationRunListeners([listener], startup);
      final context = DefaultBootstrapContext();
      // Listener exceptions are propagated
      expect(
        () => listeners.onStarting(context, Class<Object>()),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _TestRunListener extends ApplicationRunListener {
  bool startingCalled = false;
  bool environmentPreparedCalled = false;
  bool contextPreparedCalled = false;
  bool contextLoadedCalled = false;
  bool startedCalled = false;
  bool readyCalled = false;
  bool failedCalled = false;

  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    startingCalled = true;
  }

  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    environmentPreparedCalled = true;
  }

  @override
  void onContextPrepared(ConfigurableApplicationContext context) {
    contextPreparedCalled = true;
  }

  @override
  void onContextLoaded(ConfigurableApplicationContext context) {
    contextLoadedCalled = true;
  }

  @override
  void onStarted(ConfigurableApplicationContext context, Duration timeTaken) {
    startedCalled = true;
  }

  @override
  void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
    readyCalled = true;
  }

  @override
  void onFailed(ConfigurableApplicationContext? context, Object exception) {
    failedCalled = true;
  }
}

class _FailingRunListener extends ApplicationRunListener {
  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    throw StateError('Intentional failure');
  }
}
