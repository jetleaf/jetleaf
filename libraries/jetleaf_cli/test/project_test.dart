import 'dart:io';

import 'package:jetleaf_cli/src/project_builder/development_project_builder.dart';
import 'package:jetleaf_cli/src/project_builder/production_project_builder.dart';
import 'package:jetleaf_cli/src/project_builder/project_builder.dart';
import 'package:jetleaf_cli/src/common/compiler_type.dart';
import 'package:test/test.dart';

void main() {
  group('DevelopmentProject', () {
    test('should create with file, size, and metrics', () {
      final file = File('/tmp/output.dart');
      final metrics = {'time': '1.2s', 'files': '42'};
      final project = DevelopmentProject(file, '16.0KB', metrics);

      expect(project.getLocation(), equals(file));
      expect(project.getFormattedSize(), equals('16.0KB'));
      expect(project.getMetrics(), equals(metrics));
    });

    test('should implement Project interface', () {
      final project = DevelopmentProject(File('/tmp/test'), '0B', {});
      expect(project, isA<Project>());
    });

    test('should handle empty metrics', () {
      final project = DevelopmentProject(File('/tmp/test'), '0B', {});
      expect(project.getMetrics(), isEmpty);
    });

    test('should handle large formatted size', () {
      final project = DevelopmentProject(File('/tmp/test'), '1.5MB', {});
      expect(project.getFormattedSize(), equals('1.5MB'));
    });
  });

  group('ProductionProject', () {
    test('should create with file, size, and metrics', () {
      final file = File('/tmp/output.exe');
      final metrics = {'compiler': 'AOT'};
      final project = ProductionProject(file, '5.2MB', metrics);

      expect(project.getLocation(), equals(file));
      expect(project.getFormattedSize(), equals('5.2MB'));
      expect(project.getMetrics(), equals(metrics));
    });

    test('should implement Project interface', () {
      final project = ProductionProject(File('/tmp/test'), '0B', {});
      expect(project, isA<Project>());
    });
  });

  group('DevelopmentProjectBuilder', () {
    test('should create with output file', () {
      final output = File('/tmp/bootstrap.dart');
      final builder = DevelopmentProjectBuilder(output);
      expect(builder, isA<ProjectBuilder>());
    });
  });

  group('ProductionProjectBuilder', () {
    test('should create with compiler type, output, and source', () {
      final builder = ProductionProjectBuilder(
        CompilerType.JIT,
        '/tmp/output',
        '/tmp/source',
      );
      expect(builder, isA<ProjectBuilder>());
    });

    test('should create with AOT compiler', () {
      final builder = ProductionProjectBuilder(
        CompilerType.AOT,
        '/tmp/output',
        '/tmp/source',
      );
      expect(builder, isA<ProjectBuilder>());
    });

    test('should create with EXE compiler', () {
      final builder = ProductionProjectBuilder(
        CompilerType.EXE,
        '/tmp/output',
        '/tmp/source',
      );
      expect(builder, isA<ProjectBuilder>());
    });
  });
}
