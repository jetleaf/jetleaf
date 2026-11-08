import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'src/services/command_processor.dart';
import 'src/lifecycle/cli_lifecycle.dart';
import 'src/runners/app_runner.dart';
import 'src/runners/batch_runner.dart';
import 'src/exit/cli_exit_code_generator.dart';
import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class CliApp {
  static final Log _logger = LogFactory.getLog(CliApp);
}

Future<int> main(List<String> args) async {
  CliApp._logger.info('Starting CliApp execution...');
  final effectiveArgs = args.isEmpty ? ['--mode=batch', '--dry-run', 'data1.csv', 'data2.csv'] : args;
  
  final app = JetleafApplication(CliApp);
  app.setApplicationType(ApplicationType.NONE);
  app.setAotRegistrar(registerGeneratedAotPods);
  
  final context = await app.create(effectiveArgs, null);
  
  if (context == null) {
    print('Failed to start application context');
    return 1;
  }
  
  final processor = await context.getPod<CommandProcessor>('commandProcessor');
  final lifecycle = await context.getPod<CliLifecycle>('cliLifecycle');
  final appRunner = await context.getPod<AppRunner>('appRunner');
  final batchRunner = await context.getPod<BatchRunner>('batchRunner');
  final exitGen = await context.getPod<CliExitCodeGenerator>('cliExitCodeGenerator');
  
  print('================ CLI APP EXECUTION REPORT ================');
  print('Supports NONE (CLI): ${context.supports(ApplicationType.NONE)}');
  print('Lifecycle Initialized: ${lifecycle.isInitialized}');
  print('Lifecycle Ready: ${lifecycle.isReady}');
  print('AppRunner executed: ${appRunner.executed}');
  print('BatchRunner executed: ${batchRunner.executed}');
  print('Processed tasks count: ${processor.taskCount}');
  print('Processed tasks: ${processor.processedTasks}');
  print('Exit code: ${exitGen.getExitCode()}');
  print('==========================================================');

  if (effectiveArgs.contains('--fail')) {
    exitGen.setExitCode(42);
  }

  final code = await JetleafApplication.exit(context, [exitGen]);
  exit(code);
}
