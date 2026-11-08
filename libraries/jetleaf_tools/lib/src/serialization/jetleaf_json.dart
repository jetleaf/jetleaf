import 'dart:convert';

/// Shared formatter for generated Jetleaf JSON documents.
///
/// Protocol messages should continue using compact [jsonEncode]; this helper
/// is for persisted project metadata, caches, manifests, and reports.
abstract final class JetleafJson {
  const JetleafJson._();

  static String encode(Object? value) => '${const JsonEncoder.withIndent('    ').convert(value)}\n';
}
