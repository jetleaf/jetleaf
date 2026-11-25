import 'package:jetleaf_tools/src/vm/reload_hooks.dart';
import 'package:test/test.dart';
import '../helpers/aot_test_setup.dart' show ensureTestAotRegisteredSync;

void main() {
  ensureTestAotRegisteredSync();

  setUp(() => ReloadHooks.reset());
  tearDown(() => ReloadHooks.reset());

  test('reload request reaches the registered handler', () async {
    ReloadRequest? seen;
    ReloadHooks.onReload((request) async {
      seen = request;
      return ReloadOutcome(ok: true, entries: const ['lib/main.dart']);
    });

    final outcome = await ReloadHooks.reload(
      const ReloadRequest(trigger: ToolingTrigger.panel, entry: 'lib/main.dart'),
      fallback: (request) async => ReloadOutcome.failure('fallback used'),
    );

    expect(seen, isNotNull);
    expect(seen!.trigger, ToolingTrigger.panel);
    expect(seen!.entry, 'lib/main.dart');
    expect(outcome.ok, isTrue);
    expect(outcome.entries, ['lib/main.dart']);
  });

  test('restart request reaches the registered handler', () async {
    RestartRequest? seen;
    ReloadHooks.onRestart((request) async {
      seen = request;
      return const ReloadOutcome(ok: true, entries: ['test/app_test.dart']);
    });

    final outcome = await ReloadHooks.restart(
      const RestartRequest(trigger: ToolingTrigger.command),
      fallback: (request) async => ReloadOutcome.failure('fallback used'),
    );

    expect(seen, isNotNull);
    expect(seen!.trigger, ToolingTrigger.command);
    expect(outcome.ok, isTrue);
    expect(outcome.entries, ['test/app_test.dart']);
  });

  test('falls back when no handler is registered', () async {
    final reload = await ReloadHooks.reload(
      const ReloadRequest(),
      fallback: (request) async => ReloadOutcome.failure('used fallback'),
    );
    final restart = await ReloadHooks.restart(
      const RestartRequest(),
      fallback: (request) async => const ReloadOutcome(ok: true),
    );

    expect(reload.ok, isFalse);
    expect(reload.message, 'used fallback');
    expect(restart.ok, isTrue);
  });
}