import 'package:jetleaf/jetleaf.dart';
import '../services/command_processor.dart';

@Component()
class BatchRunner implements CommandLineRunner {
  static final Log _logger = LogFactory.getLog(BatchRunner);

  final CommandProcessor _processor;
  bool executed = false;
  List<String> rawArgsReceived = [];

  BatchRunner(this._processor);

  @override
  int getOrder() => 2;

  @override
  void run(List<String> args) {
    executed = true;
    rawArgsReceived = List.from(args);
    _logger.info('BatchRunner: CommandLineRunner received raw args: $args');
    
    final nonOptionArgs = args.where((arg) => !arg.startsWith('--')).toList();
    for (final file in nonOptionArgs) {
      _processor.processTask('File:$file', dryRun: args.contains('--dry-run'));
    }
  }
}