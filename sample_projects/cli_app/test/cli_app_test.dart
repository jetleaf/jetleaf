import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:cli_app/cli_app.dart';
import 'package:cli_app/src/services/command_processor.dart';
import 'package:cli_app/src/lifecycle/cli_lifecycle.dart';
import 'package:cli_app/src/runners/app_runner.dart';
import 'package:cli_app/src/runners/batch_runner.dart';
import 'package:cli_app/src/exit/cli_exit_code_generator.dart';
import 'package:cli_app/_jetleaf/aot_registry.g.dart';

void main() {
  group('CliApp Tests', () {
    test('starts context in CLI mode and executes runners in priority order', () async {
      final app = JetleafApplication(CliApp);
      app.setApplicationType(ApplicationType.NONE);
      app.setAotRegistrar(registerGeneratedAotPods);

      final context = await app.create(['--mode=test', '--dry-run', 'sample.txt'], null);

      expect(context, isNotNull);
      expect(context!.supports(ApplicationType.NONE), isTrue);

      final processor = await context.getPod<CommandProcessor>('commandProcessor');
      expect(processor.taskCount, greaterThan(0));

      final lifecycle = await context.getPod<CliLifecycle>('cliLifecycle');
      expect(lifecycle.isInitialized, isTrue);

      final appRunner = await context.getPod<AppRunner>('appRunner');
      expect(appRunner.executed, isTrue);
      expect(appRunner.getOrder(), equals(1));

      final batchRunner = await context.getPod<BatchRunner>('batchRunner');
      expect(batchRunner.executed, isTrue);
      expect(batchRunner.getOrder(), equals(2));

      final exitGen = await context.getPod<CliExitCodeGenerator>('cliExitCodeGenerator');
      final exitCode = await JetleafApplication.exit(context, [exitGen]);
      expect(exitCode, equals(0));
    });
  });
}
