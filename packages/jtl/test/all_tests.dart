import 'package:test/test.dart';

import 'template_cache_test.dart' as template_cache_test;
import 'filter_registry_test.dart' as filter_registry_test;
import 'expression_evaluator_test.dart' as expression_evaluator_test;
import 'source_code_test.dart' as source_code_test;
import 'template_renderer_test.dart' as template_renderer_test;
import 'variable_resolver_test.dart' as variable_resolver_test;
import 'jtl_factory_test.dart' as jtl_factory_test;

void main() {
  group('template_cache', () {
    template_cache_test.main();
  });
  group('filter_registry', () {
    filter_registry_test.main();
  });
  group('expression_evaluator', () {
    expression_evaluator_test.main();
  });
  group('source_code', () {
    source_code_test.main();
  });
  group('template_renderer', () {
    template_renderer_test.main();
  });
  group('variable_resolver', () {
    variable_resolver_test.main();
  });
  group('jtl_factory', () {
    jtl_factory_test.main();
  });
}
