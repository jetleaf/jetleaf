import 'package:test/test.dart';

import 'commons_test.dart' as commons_test;
import 'compiler_type_test.dart' as compiler_type_test;
import 'constant_test.dart' as constant_test;
import 'file_event_test.dart' as file_event_test;
import 'format_support_test.dart' as format_support_test;
import 'import_support_test.dart' as import_support_test;
import 'logger_test.dart' as logger_test;
import 'panel_view_test.dart' as panel_view_test;
import 'project_test.dart' as project_test;
import 'spinner_test.dart' as spinner_test;
import 'utils_test.dart' as utils_test;

void main() {
  group('Commons Tests', commons_test.main);
  group('CompilerType Tests', compiler_type_test.main);
  group('Constant Tests', constant_test.main);
  group('FileEvent Tests', file_event_test.main);
  group('FormatSupport Tests', format_support_test.main);
  group('ImportSupport Tests', import_support_test.main);
  group('Logger Tests', logger_test.main);
  group('PanelView Tests', panel_view_test.main);
  group('Project Tests', project_test.main);
  group('Spinner Tests', spinner_test.main);
  group('Utils Tests', utils_test.main);
}
