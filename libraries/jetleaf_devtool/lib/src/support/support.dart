import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart' hide FunctionDeclaration;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../common/logger.dart';
import '../common/spinner.dart';
import '../utils.dart';

part 'import_support.dart';
part 'package_support.dart';
part 'format_support.dart';
part 'writing_support.dart';
part 'generative_support.dart';

/// {@template support}
/// Core project builder support utilities for the Jetleaf framework.
///
/// This file provides foundational abstractions and utilities used
/// throughout Jetleaf’s code generation, bootstrap, and project
/// initialization processes. It organizes functionality into modular
/// parts to support different aspects of project building:
///
/// - `import_support.dart`: Contains helpers for discovering Dart source files
///   in a project and generating proper import statements. This includes
///   handling `package:` URIs, relative paths, and generated import aliases
///   to avoid naming collisions.
///
/// - `package_support.dart`: Provides utilities to convert file system paths
///   into valid Dart package URIs. Handles both absolute and relative paths
///   and ensures consistent resolution for source code generation.
///
/// - `format_support.dart`: Includes helpers for formatting command-line
///   arguments, directory lists, and other code literals. Supports
///   both inline and multi-line formatting for readability in generated
///   Dart code.
///
/// - `writing_support.dart`: Implements file writing and code output helpers,
///   including writing structured imports, main entry functions, file headers,
///   and bootstrap code. Ensures directories exist and code is written
///   deterministically.
///
/// This file also imports core dependencies such as:
/// - `dart:io` for file system operations.
/// - `package:jetleaf_lang/lang.dart` for Jetleaf language utilities.
/// - `package:meta/meta.dart` for annotations like `@protected`.
/// - `package:path/path.dart` for cross-platform path operations.
/// - Common utilities like [Logger] and [Spinner] for progress feedback.
///
/// ### The [Support] interface
///
/// The [Support] interface acts as a marker or common base for all
/// support classes in the Jetleaf project builder framework. While it
/// does not define any methods itself, it provides a common type that
/// can be used for:
/// - Dependency injection or type constraints in project builders.
/// - Identifying and grouping support-related utilities.
/// - Enforcing a consistent design pattern across builder modules.
///
/// ### Usage Example
/// ```dart
/// class MyProjectSupport extends Support {
///   // Implement additional support functionality here
/// }
/// ```
///
/// In general, concrete support classes will extend one of the parts
/// defined in this file (e.g., `FormatSupport`,
/// `WritingSupport`) and implement specific logic for
/// code generation, formatting, and file management.
///
/// This modular design allows Jetleaf to provide a flexible and
/// extensible code generation pipeline, enabling projects to
/// automatically generate bootstrap code, import statements, and
/// other boilerplate consistently.
/// {@endtemplate}
abstract interface class Support {
  /// {@macro support}
  const Support();
}