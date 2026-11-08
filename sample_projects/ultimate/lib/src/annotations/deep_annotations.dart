// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Deep Annotation Hierarchy Test
// ---------------------------------------------------------------------------

import 'package:jetleaf_core/lang.dart';
import 'package:meta/meta_meta.dart';

/// Level 1: Root Audit Marker
@Target({TargetKind.classType, TargetKind.method})
abstract class AuditRoot extends ReflectableAnnotation {
  final String domain;
  const AuditRoot(this.domain);
}

/// Level 2: Security Boundary Marker inheriting from AuditRoot
@Target({TargetKind.classType, TargetKind.method})
class SecurityBoundary extends AuditRoot {
  final int clearanceLevel;
  const SecurityBoundary(super.domain, {this.clearanceLevel = 1});

  @override
  Type get annotationType => SecurityBoundary;
}

/// Level 3: Compliance Audit Marker inheriting from SecurityBoundary
@Target({TargetKind.classType, TargetKind.method})
class ComplianceAudit extends SecurityBoundary {
  final String regulation;
  const ComplianceAudit(
    super.domain, {
    super.clearanceLevel = 2,
    this.regulation = 'ISO27001',
  });

  @override
  Type get annotationType => ComplianceAudit;
}

/// Level 4: Leaf PCI-DSS specialized annotation
@Target({TargetKind.classType, TargetKind.method})
final class PciDssAudit extends ComplianceAudit {
  final String merchantId;
  const PciDssAudit(
    super.domain, {
    super.clearanceLevel = 3,
    super.regulation = 'PCI-DSS-v4.0',
    required this.merchantId,
  });

  @override
  Type get annotationType => PciDssAudit;
}