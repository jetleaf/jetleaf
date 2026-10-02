import 'dart:convert';

import 'package:jetleaf_build/src/serialization/jetleaf_json.dart';
import 'package:jetleaf_build/src/vm/jetleaf_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Jetleaf.VM file format', () {
    test('entry array serializes with 4-space indent', () {
      final statuses = [
        EntryStatus(
            record: const EntryRecord(
                file: 'lib/main.dart', kind: EntryKind.entry),
            state: EntryState.running)
          ..pid = 12345,
        EntryStatus(
            record: const EntryRecord(
                file: 'test/app_test.dart', kind: EntryKind.test),
            state: EntryState.parked),
      ];
      final text =
          '${const JsonEncoder.withIndent('    ').convert(statuses.map((s) => s.toJson()).toList())}\n';

      // 4-space indent, array of entry objects.
      expect(text.startsWith('[\n    {'), isTrue);
      final decoded = jsonDecode(text) as List;
      expect(decoded, hasLength(2));
      expect(decoded[0]['file'], 'lib/main.dart');
      expect(decoded[0]['kind'], 'entry');
      expect(decoded[0]['state'], 'running');
      expect(decoded[0]['pid'], 12345);
      expect(decoded[1]['kind'], 'test');
    });

    test('shared persisted JSON formatter uses four-space indentation', () {
      final text = JetleafJson.encode({
        'pid': 12345,
        'state': 'running',
      });

      expect(text, startsWith('{\n    "pid": 12345,\n'));
      expect(text, endsWith('\n'));
      expect(jsonDecode(text), {'pid': 12345, 'state': 'running'});
    });
  });
}
