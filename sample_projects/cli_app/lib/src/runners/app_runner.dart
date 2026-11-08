import 'package:jetleaf/jetleaf.dart';
import '../services/command_processor.dart';

@Component()
class AppRunner implements ApplicationRunner {
  static final Log _logger = LogFactory.getLog(AppRunner);

  final CommandProcessor _processor;
  bool executed = false;
  List<String> optionsReceived = [];

  AppRunner(this._processor);

  @override
  int getOrder() => 1;

  @override
  void run(ApplicationArguments args) {
    executed = true;
    _logger.info('AppRunner: ApplicationRunner invoked with option names: ${args.getOptionNames()}');
    for (final name in args.getOptionNames()) {
      final values = args.getOptionValues(name);
      optionsReceived.add('$name=$values');
      _processor.processTask('Option:$name($values)', dryRun: args.containsOption('dry-run'));
    }
  }
}
