/// 🛠 **Jetleaf CLI**
///
/// The Jetleaf Devtool provides a set of development utilities for
/// Jetleaf projects, including CLI tools, project building, file
/// watching, and command execution support.
///
/// This library is designed to streamline development workflows,
/// automate repetitive tasks, and provide live feedback during
/// project development.
///
///
/// ## 🔑 Core Components
///
/// ### 💻 Command-Line Interface
/// - `cli.dart` — core CLI entry point and interface for executing
///   development tasks
///
/// ### 🏃 Command Runner
/// - `command_runner.dart` — executes registered commands with
///   arguments and manages command lifecycle
///
/// ### 📦 Project Builder
/// - `project_builder.dart` — handles project compilation, build
///   scripts, and automated project tasks
///
/// ### 🔧 Support Utilities
/// - `support.dart` — helper functions and utilities to support
///   development operations
///
/// ### 👀 File & Project Watchers
/// - `file_watcher.dart` — watches files for changes and triggers
///   configured actions
/// - `project_watcher.dart` — monitors the project directory and
///   automates tasks such as rebuilds, reloads, or other developer
///   workflows
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to integrate development tooling into your
/// Jetleaf project:
/// ```dart
/// import 'package:jetleaf_cli/jetleaf_cli.dart';
///
/// final watcher = ProjectWatcher();
/// watcher.watch();
/// ```
///
/// Provides automated file watching, command execution, and project
/// building capabilities to enhance the developer experience.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'src/cli/cli.dart';
export 'src/project/jetleaf_paths.dart';
export 'src/project/project_state.dart';
export 'src/project/toolchain_versions.dart';
export 'src/project/context_metadata.dart';
export 'src/cli/jetleaf_cli.dart';
export 'src/command_runner/command_runner.dart' hide frontendClient, compilationResult;
export 'src/project_builder/project_builder.dart';
export 'src/support/support.dart';
export 'src/watcher/file_watcher.dart';
export 'src/watcher/project_watcher.dart';
