import 'package:jetleaf_build/src/vm/jetleaf_vm.dart';
import 'package:test/test.dart';

void main() {
  test('log records preserve raw fields and format human output', () {
    final record = JetleafLogRecord(
      timestamp: DateTime(2026, 1, 2, 3, 4, 5),
      level: JetleafLogLevel.warning,
      message: 'cache needs refresh',
      source: 'vm',
      entry: 'test/example_test.dart',
      phase: 'warm',
    );

    final event = record.toEvent();
    expect(event['message'], 'cache needs refresh');
    expect(event['level'], 'warning');
    expect(event['source'], 'vm');
    expect(event['entry'], 'test/example_test.dart');
    expect(event['formatted'], contains('[WARNING] [vm] [test/example_test.dart]'));
  });

  test('banner records stay unprefixed', () {
    final record = JetleafLogRecord(
      timestamp: DateTime(2026),
      level: JetleafLogLevel.info,
      message: 'JETLEAF',
      source: 'manager',
      banner: true,
    );

    expect(record.formatted, 'JETLEAF');
  });
}
