import 'package:test/test.dart';

import 'annotation_aware_order_comparator_test.dart' as annotation_aware_order_comparator_test;
import 'scope/scope_metadata_resolver_test.dart' as scope_metadata_resolver_test;
import 'scope/annotated_scope_metadata_resolver_test.dart' as annotated_scope_metadata_resolver_test;
import 'message/delegating_message_source_test.dart' as delegating_message_source_test;
import 'message/message_source_loader_test.dart' as message_source_loader_test;
import 'message/abstract_message_source_test.dart' as abstract_message_source_test;
import 'message/configurable_message_source_test.dart' as configurable_message_source_test;
import 'context/base/pod_factory_customizer_test.dart' as pod_factory_customizer_test;
import 'context/base/pod_registrar_test.dart' as pod_registrar_test;
import 'context/base/application_module_test.dart' as application_module_test;
import 'context/base/application_context_test.dart' as application_context_test;
import 'context/base/keep_alive_test.dart' as keep_alive_test;
import 'context/base/pod_spec_test.dart' as pod_spec_test;
import 'context/exit/exit_code_event_test.dart' as exit_code_event_test;
import 'context/exit/exit_code_generator_test.dart' as exit_code_generator_test;
import 'context/type_filter/assignable_type_filter_test.dart' as assignable_type_filter_test;
import 'context/type_filter/regex_pattern_type_filter_test.dart' as regex_pattern_type_filter_test;
import 'context/type_filter/annotation_type_filter_test.dart' as annotation_type_filter_test;
import 'context/processors/configuration_property_pod_processor_test.dart' as configuration_property_pod_processor_test;
import 'context/lifecycle/lifecycle_test.dart' as lifecycle_test;
import 'context/core/pod_post_processor_manager_test.dart' as pod_post_processor_manager_test;
import 'intercept/intercept_test.dart' as intercept_test;
import 'availability/availability_test.dart' as availability_test;
import 'event/application_event_test.dart' as application_event_test;
import 'diagnostics/exception_diagnosis_test.dart' as exception_diagnosis_test;

void main() {
  group('annotation_aware_order_comparator', () {
    annotation_aware_order_comparator_test.main();
  });
  group('scope_metadata_resolver', () {
    scope_metadata_resolver_test.main();
  });
  group('annotated_scope_metadata_resolver', () {
    annotated_scope_metadata_resolver_test.main();
  });
  group('delegating_message_source', () {
    delegating_message_source_test.main();
  });
  group('message_source_loader', () {
    message_source_loader_test.main();
  });
  group('abstract_message_source', () {
    abstract_message_source_test.main();
  });
  group('configurable_message_source', () {
    configurable_message_source_test.main();
  });
  group('pod_factory_customizer', () {
    pod_factory_customizer_test.main();
  });
  group('pod_registrar', () {
    pod_registrar_test.main();
  });
  group('application_module', () {
    application_module_test.main();
  });
  group('application_context', () {
    application_context_test.main();
  });
  group('keep_alive', () {
    keep_alive_test.main();
  });
  group('pod_spec', () {
    pod_spec_test.main();
  });
  group('exit_code_event', () {
    exit_code_event_test.main();
  });
  group('exit_code_generator', () {
    exit_code_generator_test.main();
  });
  group('assignable_type_filter', () {
    assignable_type_filter_test.main();
  });
  group('regex_pattern_type_filter', () {
    regex_pattern_type_filter_test.main();
  });
  group('annotation_type_filter', () {
    annotation_type_filter_test.main();
  });
  group('configuration_property_pod_processor', () {
    configuration_property_pod_processor_test.main();
  });
  group('lifecycle', () {
    lifecycle_test.main();
  });
  group('pod_post_processor_manager', () {
    pod_post_processor_manager_test.main();
  });
  group('intercept', () {
    intercept_test.main();
  });
  group('availability', () {
    availability_test.main();
  });
  group('application_event', () {
    application_event_test.main();
  });
  group('exception_diagnosis', () {
    exception_diagnosis_test.main();
  });
}