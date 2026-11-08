import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/logging.dart';

@Service()
class CommandProcessor {
  static final Log _logger = LogFactory.getLog(CommandProcessor);

  final List<String> _processedTasks = [];

  List<String> get processedTasks => List.unmodifiable(_processedTasks);

  void processTask(String taskName, {bool dryRun = false}) {
    if (dryRun) {
      _logger.info('[DRY RUN] Would process task: $taskName');
      _processedTasks.add('dry-run:$taskName');
    } else {
      _logger.info('Processing task: $taskName');
      _processedTasks.add('executed:$taskName');
    }
  }

  int get taskCount => _processedTasks.length;
}