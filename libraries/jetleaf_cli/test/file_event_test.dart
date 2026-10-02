import 'dart:io';

import 'package:jetleaf_cli/jetleaf_cli.dart';
import 'package:test/test.dart';

void main() {
  group('FileEvent', () {
    late File testFile;

    setUp(() {
      testFile = File('/tmp/test_file.txt');
    });

    group('CreatedFileEvent', () {
      test('should create with file', () {
        final event = CreatedFileEvent(testFile);
        expect(event.getSource(), equals(testFile));
      });

      test('should be a FileEvent', () {
        final event = CreatedFileEvent(testFile);
        expect(event, isA<FileEvent>());
      });

      test('should return the correct source file', () {
        final file = File('/path/to/new_file.dart');
        final event = CreatedFileEvent(file);
        expect(event.getSource().path, equals('/path/to/new_file.dart'));
      });
    });

    group('DeletedFileEvent', () {
      test('should create with file', () {
        final event = DeletedFileEvent(testFile);
        expect(event.getSource(), equals(testFile));
      });

      test('should be a FileEvent', () {
        final event = DeletedFileEvent(testFile);
        expect(event, isA<FileEvent>());
      });
    });

    group('ModifiedFileEvent', () {
      test('should create with file', () {
        final event = ModifiedFileEvent(testFile);
        expect(event.getSource(), equals(testFile));
      });

      test('should be a FileEvent', () {
        final event = ModifiedFileEvent(testFile);
        expect(event, isA<FileEvent>());
      });
    });

    group('RenamedFileEvent', () {
      test('should create with new and old file', () {
        final oldFile = File('/tmp/old_name.txt');
        final newFile = File('/tmp/new_name.txt');
        final event = RenamedFileEvent(newFile, oldFile);
        expect(event.getSource(), equals(newFile));
        expect(event.getOldSource(), equals(oldFile));
      });

      test('should create with null old file', () {
        final event = RenamedFileEvent(testFile, null);
        expect(event.getSource(), equals(testFile));
        expect(event.getOldSource(), isNull);
      });

      test('should be a FileEvent', () {
        final event = RenamedFileEvent(testFile, null);
        expect(event, isA<FileEvent>());
      });
    });
  });
}
