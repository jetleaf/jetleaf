import 'package:jetleaf_utils/jetleaf_utils.dart';
import 'package:test/test.dart';

void main() {
  group('TraceFrame', () {
    group('constructor', () {
      test('creates frame with all fields', () {
        final frame = TraceFrame(
          hierarchy: 0,
          className: 'MyClass',
          methodName: 'myMethod',
          packageUri: 'package:example/file.dart',
          lineNumber: 10,
          column: 5,
          raw: '#0 MyClass.myMethod (package:example/file.dart:10:5)',
        );

        expect(frame.hierarchy, 0);
        expect(frame.packageUri, 'package:example/file.dart');
        expect(frame.lineNumber, 10);
        expect(frame.column, 5);
        expect(frame.getClassName(), 'MyClass');
        expect(frame.getMethodName(), 'myMethod');
      });

      test('defaults className and methodName to unknown when null', () {
        final frame = TraceFrame(
          hierarchy: 1,
          packageUri: 'package:example/file.dart',
          lineNumber: 10,
          column: 5,
          raw: '#1 top_function',
        );

        expect(frame.getClassName(), isNull);
        expect(frame.getMethodName(), isNull);
      });
    });

    group('empty constructor', () {
      test('creates frame with defaults', () {
        final frame = TraceFrame.empty('#0 something');

        expect(frame.hierarchy, -1);
        expect(frame.getClassName(), isNull);
        expect(frame.getMethodName(), isNull);
        expect(frame.packageUri, '');
        expect(frame.lineNumber, 0);
        expect(frame.column, 0);
      });
    });

    group('isTopLevelFunction', () {
      test('returns true when no class name', () {
        final frame = TraceFrame(
          hierarchy: 0,
          methodName: 'main',
          packageUri: 'package:example/main.dart',
          lineNumber: 1,
          column: 1,
          raw: '#0 main',
        );

        expect(frame.isTopLevelFunction(), isTrue);
      });

      test('returns false when class name is present', () {
        final frame = TraceFrame(
          hierarchy: 0,
          className: 'MyClass',
          methodName: 'myMethod',
          packageUri: 'package:example/file.dart',
          lineNumber: 1,
          column: 1,
          raw: '#0 MyClass.myMethod',
        );

        expect(frame.isTopLevelFunction(), isFalse);
      });
    });

    group('getFileName', () {
      test('extracts filename from package URI', () {
        final frame = TraceFrame(
          hierarchy: 0,
          packageUri: 'package:example/service/advisable.dart',
          lineNumber: 1,
          column: 1,
          raw: '',
        );

        expect(frame.getFileName(), 'advisable.dart');
      });

      test('returns null for empty package URI', () {
        final frame = TraceFrame.empty('');
        expect(frame.getFileName(), isNull);
      });

      test('returns full URI if no slash', () {
        final frame = TraceFrame(
          hierarchy: 0,
          packageUri: 'file.dart',
          lineNumber: 1,
          column: 1,
          raw: '',
        );

        expect(frame.getFileName(), 'file.dart');
      });
    });

    group('toString', () {
      test('formats with class and method', () {
        final frame = TraceFrame(
          hierarchy: 2,
          className: 'MyService',
          methodName: 'processRequest',
          packageUri: 'package:example/service.dart',
          lineNumber: 45,
          column: 12,
          raw: '',
        );

        expect(frame.toString(), '#2 MyService.processRequest (package:example/service.dart:45:12)');
      });

      test('formats with method only', () {
        final frame = TraceFrame(
          hierarchy: 0,
          methodName: 'main',
          packageUri: 'package:example/main.dart',
          lineNumber: 1,
          column: 1,
          raw: '',
        );

        expect(frame.toString(), '#0 main (package:example/main.dart:1:1)');
      });

      test('formats empty frame', () {
        final frame = TraceFrame.empty('#0 unknown');
        expect(frame.toString(), '(:0:0)');
      });
    });
  });
}
