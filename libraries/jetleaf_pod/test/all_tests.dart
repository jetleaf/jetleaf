import 'package:test/test.dart';

import 'core/abstract_pod_factory_test.dart' as abstract_pod_factory_test;
import 'core/abstract_pod_provider_factory_test.dart' as abstract_pod_provider_factory_test;
import 'core/default_listable_pod_factory_test.dart' as default_listable_pod_factory_test;
import 'definition/abstract_pod_definition_test.dart' as abstract_pod_definition_test;
import 'definition/autowire_descriptor_test.dart' as autowire_descriptor_test;
import 'definition/dependency_descriptor_test.dart' as dependency_descriptor_test;
import 'definition/design_descriptor_test.dart' as design_descriptor_test;
import 'definition/factory_method_descriptor_test.dart' as factory_method_descriptor_test;
import 'definition/lifecycle_design_test.dart' as lifecycle_design_test;
import 'definition/listable_pod_definition_registry_test.dart' as listable_pod_definition_registry_test;
import 'definition/pod_definition_registry_test.dart' as pod_definition_registry_test;
import 'definition/pod_definition_test.dart' as pod_definition_test;
import 'definition/root_pod_definition_test.dart' as root_pod_definition_test;
import 'definition/scope_descriptor_test.dart' as scope_descriptor_test;
import 'definition/simple_pod_definition_registry_test.dart' as simple_pod_definition_registry_test;
import 'expression/pod_expression_test.dart' as pod_expression_test;
import 'helpers/argument_value_test.dart' as argument_value_test;
import 'helpers/autowire_mode_test.dart' as autowire_mode_test;
import 'helpers/constructor_argument_value_test.dart' as constructor_argument_value_test;
import 'helpers/convertible_value_test.dart' as convertible_value_test;
import 'helpers/dependency_check_test.dart' as dependency_check_test;
import 'helpers/design_role_test.dart' as design_role_test;
import 'helpers/mergeable_test.dart' as mergeable_test;
import 'helpers/mutable_property_value_test.dart' as mutable_property_value_test;
import 'helpers/nullable_pod_test.dart' as nullable_pod_test;
import 'helpers/object_factory_test.dart' as object_factory_test;
import 'helpers/object_holder_test.dart' as object_holder_test;
import 'helpers/object_provider_test.dart' as object_provider_test;
import 'helpers/pod_provider_test.dart' as pod_provider_test;
import 'helpers/pod_utils_test.dart' as pod_utils_test;
import 'helpers/property_value_test.dart' as property_value_test;
import 'helpers/property_values_test.dart' as property_values_test;
import 'helpers/scope_type_test.dart' as scope_type_test;
import 'helpers/scoped_object_factory_test.dart' as scoped_object_factory_test;
import 'lifecycle/auto_closeable_test.dart' as auto_closeable_test;
import 'lifecycle/disposable_lifecycle_manager_test.dart' as disposable_lifecycle_manager_test;
import 'lifecycle/disposable_pod_test.dart' as disposable_pod_test;
import 'lifecycle/init_methods_manager_test.dart' as init_methods_manager_test;
import 'name_generator/pod_name_generator_test.dart' as pod_name_generator_test;
import 'name_generator/simple_pod_name_generator_test.dart' as simple_pod_name_generator_test;
import 'scope/prototype_scope_test.dart' as prototype_scope_test;
import 'scope/singleton_scope_test.dart' as singleton_scope_test;
import 'singleton/singleton_pod_registry_test.dart' as singleton_pod_registry_test;
import 'startup/application_startup_aware_test.dart' as application_startup_aware_test;
import 'startup/application_startup_test.dart' as application_startup_test;
import 'startup/standard_startup_tracker_test.dart' as standard_startup_tracker_test;
import 'startup/startup_step_tag_test.dart' as startup_step_tag_test;
import 'startup/startup_step_tags_test.dart' as startup_step_tags_test;
import 'startup/startup_step_test.dart' as startup_step_test;
import 'startup/startup_tracker_test.dart' as startup_tracker_test;
import 'alias/simple_alias_registry_test.dart' as simple_alias_registry_test;

void main() {
  group('core', () {
    abstract_pod_factory_test.main();
    abstract_pod_provider_factory_test.main();
    default_listable_pod_factory_test.main();
  });

  group('definition', () {
    abstract_pod_definition_test.main();
    autowire_descriptor_test.main();
    dependency_descriptor_test.main();
    design_descriptor_test.main();
    factory_method_descriptor_test.main();
    lifecycle_design_test.main();
    listable_pod_definition_registry_test.main();
    pod_definition_registry_test.main();
    pod_definition_test.main();
    root_pod_definition_test.main();
    scope_descriptor_test.main();
    simple_pod_definition_registry_test.main();
  });

  group('expression', () {
    pod_expression_test.main();
  });

  group('helpers', () {
    argument_value_test.main();
    autowire_mode_test.main();
    constructor_argument_value_test.main();
    convertible_value_test.main();
    dependency_check_test.main();
    design_role_test.main();
    mergeable_test.main();
    mutable_property_value_test.main();
    nullable_pod_test.main();
    object_factory_test.main();
    object_holder_test.main();
    object_provider_test.main();
    pod_provider_test.main();
    pod_utils_test.main();
    property_value_test.main();
    property_values_test.main();
    scope_type_test.main();
    scoped_object_factory_test.main();
  });

  group('lifecycle', () {
    auto_closeable_test.main();
    disposable_lifecycle_manager_test.main();
    disposable_pod_test.main();
    init_methods_manager_test.main();
  });

  group('name_generator', () {
    pod_name_generator_test.main();
    simple_pod_name_generator_test.main();
  });

  group('scope', () {
    prototype_scope_test.main();
    singleton_scope_test.main();
  });

  group('singleton', () {
    singleton_pod_registry_test.main();
  });

  group('startup', () {
    application_startup_aware_test.main();
    application_startup_test.main();
    standard_startup_tracker_test.main();
    startup_step_tag_test.main();
    startup_step_tags_test.main();
    startup_step_test.main();
    startup_tracker_test.main();
  });

  group('alias', () {
    simple_alias_registry_test.main();
  });
}
