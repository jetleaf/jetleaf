// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Custom User-Defined Annotations
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:meta/meta_meta.dart';

/// Custom stereotype annotation meta-annotated with [Service].
@Target({TargetKind.classType})
class CustomService extends Service {
  const CustomService([super.value]);
}

/// Custom lifecycle annotation extending [OnApplicationReady].
@Target({TargetKind.method})
final class CustomOnReady extends OnApplicationReady {
  const CustomOnReady();

  @override
  Type get annotationType => CustomOnReady;
}

/// Custom method-level audit annotation.
@Target({TargetKind.method})
final class Audited extends ReflectableAnnotation {
  final String action;
  const Audited([this.action = 'DEFAULT_AUDIT']);

  @override
  Type get annotationType => Audited;
}

/// Custom REST controller annotation extending [RestController].
@Target({TargetKind.classType})
class CustomEndpoint extends RestController {
  const CustomEndpoint([super.value]);
}
