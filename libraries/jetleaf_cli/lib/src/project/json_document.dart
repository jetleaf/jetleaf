import 'dart:convert';
import 'dart:io';

/// A typed value that can be persisted by the Jetleaf project store.
abstract interface class JetleafJsonDocument {
  Object? toJson();
}

/// Writes deterministic, human-readable Jetleaf JSON documents.
final class JetleafJsonWriter {
  const JetleafJsonWriter();

  /// Writes [value] atomically using four-space indentation.
  Future<void> write(String path, Object? value) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp-${pid()}');
    final encoded = const JsonEncoder.withIndent('    ').convert(value);
    await temporary.writeAsString('$encoded\n', flush: true);
    if (file.existsSync()) await file.delete();
    await temporary.rename(file.path);
  }

  static int pid() => pidValue;
}

// Kept behind a top-level value so tests can replace it without coupling the
// JSON writer to process-global output formatting.
final int pidValue = DateTime.now().microsecondsSinceEpoch;
