import 'dart:io';

import 'package:jetleaf_cli/src/support/support.dart';
import 'package:test/test.dart';

class TestFormatSupport extends FormatSupport {
  const TestFormatSupport();

  // Expose protected methods for testing
  String testFormatArgs(List<String> args, [int inlineLimit = 6]) => formatArgs(args, inlineLimit);
  String testFormatDirs(Directory project, List<String> directories, [int inlineLimit = 1]) => formatDirs(project, directories, inlineLimit);
  String testFormatBytes(int bytes) => formatBytes(bytes);
}

void main() {
  const support = TestFormatSupport();

  group('FormatSupport', () {
    group('formatArgs', () {
      test('should format empty list inline', () {
        expect(support.testFormatArgs([]), equals('[]'));
      });

      test('should format single arg inline', () {
        expect(support.testFormatArgs(['--watch']), equals("['--watch']"));
      });

      test('should format multiple args inline when under limit', () {
        final result = support.testFormatArgs(['a', 'b', 'c']);
        expect(result, equals("['a', 'b', 'c']"));
      });

      test('should format args multiline when over limit', () {
        final args = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
        final result = support.testFormatArgs(args, 6);
        expect(result, startsWith('[\n'));
        expect(result, endsWith('\n]'));
        expect(result, contains("'a',"));
        expect(result, contains("'g',"));
      });

      test('should respect custom inline limit', () {
        final result = support.testFormatArgs(['a', 'b'], 1);
        expect(result, startsWith('[\n'));
      });

      test('should format args with special characters', () {
        final result = support.testFormatArgs(['--name=value', '--flag']);
        expect(result, equals("['--name=value', '--flag']"));
      });
    });

    group('formatDirs', () {
      test('should return empty list for empty directories', () {
        final project = Directory('/tmp');
        expect(support.testFormatDirs(project, []), equals('[]'));
      });

      test('should format single directory', () {
        final project = Directory('/tmp/project');
        final result = support.testFormatDirs(project, ['lib']);
        expect(result, contains("File('"));
        expect(result, contains('lib'));
      });

      test('should format absolute paths as-is', () {
        final project = Directory('/tmp/project');
        final result = support.testFormatDirs(project, ['/absolute/path']);
        expect(result, contains("/absolute/path"));
      });

      test('should join relative paths with project', () {
        final project = Directory('/tmp/project');
        final result = support.testFormatDirs(project, ['src']);
        expect(result, contains('/tmp/project'));
        expect(result, contains('src'));
      });

      test('should format multiple directories multiline', () {
        final project = Directory('/tmp/project');
        final result = support.testFormatDirs(project, ['lib', 'src', 'bin'], 1);
        expect(result, startsWith('[\n'));
        expect(result, endsWith('\n]'));
      });

      test('should skip empty directory strings', () {
        final project = Directory('/tmp/project');
        final result = support.testFormatDirs(project, ['lib', '', 'src']);
        expect(result, isNot(contains("''")));
      });
    });

    group('formatBytes', () {
      test('should format bytes', () {
        expect(support.testFormatBytes(512), equals('512B'));
      });

      test('should format zero bytes', () {
        expect(support.testFormatBytes(0), equals('0B'));
      });

      test('should format kilobytes', () {
        expect(support.testFormatBytes(16384), equals('16.0KB'));
      });

      test('should format megabytes', () {
        expect(support.testFormatBytes(5242880), equals('5.0MB'));
      });

      test('should format 1023 bytes as bytes', () {
        expect(support.testFormatBytes(1023), equals('1023B'));
      });

      test('should format exactly 1024 bytes as 1.0KB', () {
        expect(support.testFormatBytes(1024), equals('1.0KB'));
      });

      test('should format large kilobytes', () {
        expect(support.testFormatBytes(1048576), equals('1.0MB'));
      });
    });
  });
}
