import 'package:jetleaf_core/core.dart' show EntryApplicationAware;
import 'package:jetleaf_core/lang.dart' show Class, Method;

import '../../annotation/enable_web_security.dart';
import '../../annotation/security_annotations.dart';
import 'method_security_metadata_source.dart';

/// {@template enablement_aware_method_security_metadata_source}
/// A metadata source that honours the family switches on
/// `@EnableMethodSecurity`.
///
/// Expression-based annotations are exposed only when `prePostEnabled` is
/// true; `@Secured` requires `securedEnabled` and `@RolesAllowed` requires
/// `jsr250Enabled`. The underlying annotation source remains the single place
/// that reads annotation metadata.
/// {@endtemplate}
final class EnablementAwareMethodSecurityMetadataSource implements MethodSecurityMetadataSource, EntryApplicationAware {
  /// {@macro enablement_aware_method_security_metadata_source}
  EnablementAwareMethodSecurityMetadataSource();

  bool _prePostEnabled = true;
  bool _securedEnabled = false;
  bool _jsr250Enabled = false;

  @override
  void setEntryApplication(Class<Object> entryApplication) {
    final enable = entryApplication.getDirectAnnotation<EnableMethodSecurity>();
    if (enable == null) return;
    _prePostEnabled = enable.prePostEnabled;
    _securedEnabled = enable.securedEnabled;
    _jsr250Enabled = enable.jsr250Enabled;
  }

  @override
  List<Object> getAttributes(Method method) => const PrePostAnnotationSecurityMetadataSource()
    .getAttributes(method)
    .where(_isEnabled)
    .toList();

  bool _isEnabled(Object attribute) => switch (attribute) {
    PreAuthorize() || PostAuthorize() => _prePostEnabled,
    Secured() => _securedEnabled,
    RolesAllowed() => _jsr250Enabled,
    _ => false,
  };
}