import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:test/test.dart';
import '../../../lang/meta/test_data.dart' show ensureTestAotRegisteredSync;

final class _FakeRefreshablePod implements RefreshablePod {
  HotReloadDelta? lastDelta;
  int calls = 0;

  @override
  Future<void> onHotReload(HotReloadDelta delta, ApplicationContext context) async {
    calls++;
    lastDelta = delta;
  }
}

final class _FakeReloadProcessor implements ReloadAwarePodProcessor {
  int calls = 0;
  String? lastName;

  @override
  Future<void> processOnHotReload(
    Object pod,
    Class podClass,
    String name,
    HotReloadDelta delta,
  ) async {
    calls++;
    lastName = name;
  }
}

final class _TestEventListener implements ApplicationEventListener<ApplicationEvent> {
  HotReloadEvent? receivedEvent;
  HotRestartEvent? restartEvent;

  @override
  bool supportsEventOf(ApplicationEvent event) => event is HotReloadEvent || event is HotRestartEvent;

  @override
  Future<void> onApplicationEvent(ApplicationEvent event) async {
    if (event is HotReloadEvent) receivedEvent = event;
    if (event is HotRestartEvent) restartEvent = event;
  }
}

void main() {
  ensureTestAotRegisteredSync();
  group('HotReload & HotRestart', () {
    test('HotReloadDelta exposes modified classes, pods, assets, and structural flag', () {
      final delta = HotReloadDelta(
        modifiedClasses: {Class<String>()},
        addedPodNames: {'a'},
        modifiedPodNames: {'b'},
        removedPodNames: {'c'},
        modifiedAssetPaths: {'templates/index.jtl'},
        structuralChange: true,
      );

      expect(delta.getModifiedClasses(), {Class<String>()});
      expect(delta.getAddedPodNames(), {'a'});
      expect(delta.getModifiedPodNames(), {'b'});
      expect(delta.getRemovedPodNames(), {'c'});
      expect(delta.getModifiedAssetPaths(), {'templates/index.jtl'});
      expect(delta.isStructuralChange(), isTrue);
      expect(delta.isEmpty(), isFalse);
      expect(HotReloadDelta.empty.isEmpty(), isTrue);
    });

    test('notifyReload class handles keep their metadata name when the declaration Type is Object', () {
      // Build-time declarations carry `Object` as a placeholder Type. The
      // delta must expose the real metadata name, not "Object".
      final library = StandardLibraryDeclaration(
        uri: 'package:ghost/ghost.dart',
        name: 'ghost.dart',
        isPublic: true,
        isSynthetic: false,
        parentPackage: MaterialPackage(
          name: 'ghost',
          version: '1.0.0',
          isRootPackage: false,
          filePath: null,
          rootUri: null,
          dependencies: const [],
          devDependencies: const [],
          jetleafDependencies: const [],
        ),
      );
      final declaration = StandardClassDeclaration(
        name: 'GhostWidget',
        type: Object,
        isPublic: true,
        isSynthetic: false,
        library: library,
        qualifiedName: 'package:ghost/ghost.dart.GhostWidget',
      );

      expect(Class.forType(declaration.getType()).getName(), 'Object');

      final resolved = HotReloadCoordinator.classForDeclaration(declaration);
      expect(resolved.getName(), 'GhostWidget');
      expect(resolved.getQualifiedName(), 'package:ghost/ghost.dart.GhostWidget');
    });

    test('RefreshScope annotation uses refresh scope name', () {
      const scope = RefreshScope();
      expect(scope.value, 'refresh');
      expect(scope.annotationType, RefreshScope);
    });

    test('AnnotationConfigApplicationContext.triggerHotReload invokes RefreshablePod, ReloadAwarePodProcessor, RefreshPodScope, and publishes HotReloadEvent', () async {
      final refreshable = _FakeRefreshablePod();
      final context = AnnotationConfigApplicationContext();
      context.setApplicationStartup(DefaultApplicationStartup());
      context.setEnvironment(ApplicationEnvironment());
      context.setMainApplicationClass(Class.forObject(refreshable));
      final processor = _FakeReloadProcessor();
      final listener = _TestEventListener();

      context.getPodFactory().addPodProcessor(processor);
      await context.getPodFactory().registerDefinition(
        '_FakeRefreshablePod',
        RootPodDefinition(type: Class.forObject(refreshable))
          ..instanceSupplier = (_) => refreshable,
      );
      await context.addApplicationListener(listener);
      await context.setup();

      final delta = HotReloadDelta(
        modifiedClasses: {Class.forObject(refreshable)},
        modifiedAssetPaths: {'application.yaml'},
      );
      await context.triggerHotReload(delta);

      expect(refreshable.calls, 1);
      expect(refreshable.lastDelta, delta);
      expect(processor.calls, 1);
      expect(processor.lastName, '_FakeRefreshablePod');
      expect(listener.receivedEvent?.getDelta(), delta);

      await context.triggerHotRestart(delta);
      expect(listener.restartEvent?.getDelta(), delta);
      expect(context.isClosed(), isTrue);
    });
  });
}