part of 'command_runner.dart';

/// {@template info_command_runner}
/// A Jetleaf CLI command that displays comprehensive information about
/// the current Jetleaf project and its environment.
///
/// The [InfoCommandRunner] provides a user-friendly summary of project
/// metadata, framework versions, and dependency information by parsing
/// the local `pubspec.yaml`. It is designed to help developers quickly
/// verify their Jetleaf setup, dependency health, and installed framework
/// version without manually inspecting configuration files.
///
/// ### Overview
/// When executed, this command:
/// 1. Reads the `pubspec.yaml` file in the current directory.
/// 2. Parses the project metadata, including name, description, version,
///    and repository links.
/// 3. Displays information about the Jetleaf framework in use — including
///    the declared and installed versions.
/// 4. Identifies other Jetleaf-related dependencies within the project.
///
/// Output is formatted in visually boxed sections for clarity and
/// terminal readability.
///
/// ### Example Usage
/// ```bash
/// # Run from a Jetleaf project root
/// jl --info
///
/// # Example Output:
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │ 📋 PROJECT INFORMATION                                                     │
/// │                                                                            │
/// │   Name               : my_jetleaf_app                                      │
/// │   Description        : A sample Jetleaf application.                       │
/// │   Version            : 1.2.0                                               │
/// │   Repository         : https://github.com/org/my_jetleaf_app               │
/// └────────────────────────────────────────────────────────────────────────────┘
///
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │ 🚀 JETLEAF FRAMEWORK                                                       │
/// │                                                                            │
/// │   Version in pubspec  : ^0.9.0                                            │
/// │   Installed version   : 0.9.2                                             │
/// │                                                                            │
/// │   Other Jetleaf packages:                                                 │
/// │     • jetleaf_ui: ^0.9.0                                                  │
/// │     • jetleaf_router: ^0.8.1                                              │
/// └────────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ### Behavior
/// - If no `pubspec.yaml` is found in the current directory, an error is
///   logged and the command exits gracefully.
/// - If parsing fails (e.g., due to invalid YAML), a detailed error message
///   is displayed with contextual hints.
/// - The command supports standard Jetleaf CLI logging through [CliLogger].
///
/// ### References
/// - [CommandRunner] — Base class for Jetleaf command executors.
/// - [CliLogger] — Provides structured output for CLI operations.
/// - [YamlParser] — Used to parse the `pubspec.yaml` file content.
/// - [JetleafVersion] — Provides runtime framework version lookup.
/// - [cliSession] — Contextual session used to obtain command-scoped loggers.
/// {@endtemplate}
final class InfoCommandRunner extends CommandRunner {
  /// Creates a new [InfoCommandRunner] instance.
  ///
  /// This command runner can be invoked through the Jetleaf CLI using
  /// the `jl --info` command. It does not require any arguments and is
  /// safe to execute in read-only contexts.
  /// 
  /// {@macro info_command_runner}
  const InfoCommandRunner();

  @override
  String get command => '--info';

  @override
  String get description => 'Displays comprehensive information about the current Jetleaf project and dependencies.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command

Description:
  $description
  
Shows project details from pubspec.yaml including:
  - Project name, version, and description
  - Homepage, repository, and documentation links
  - Current Jetleaf framework version in use
  - Dependency information and project metadata

When using no-interact in allowed commands, common environment keys are:
  - JL_ENTRY              The entry path that contains the main function (eg. lib/main.dart)
  - JL_PATH_FOLDER        The folder where the generated executable will be stored (eg. build)
  - JL_EXEC_NAME          The name of the executable file (eg. server)
  - JL_BUILD_EXCLUDE      The list of packages to exclude from scanning (eg. build, analyzer)
  - JL_BUILD_INCLUDE      The list of packages to include when scanning (eg. build, analyzer)
''';

  @override
  Future<void> run(List<String> args) async {
    final currentDir = Directory.current;
    final pubspecFile = File('${currentDir.path}/pubspec.yaml');
    
    if (!await pubspecFile.exists()) {
      logger.error('No pubspec.yaml found in the current directory.');
      logger.info('Please run this command from your Jetleaf project root.');
      return;
    }

    try {
      // Parse local pubspec.yaml
      final pubspecContent = await pubspecFile.readAsString();
      final parser = YamlParser();
      final asset = AssetResource(pubspecContent);
      final parsed = parser.parseAsset(asset);

      // Display project information in a box
      _printBoxedInfo(parsed, logger);
      
    } catch (e) {
      logger.error('Error reading pubspec.yaml: $e');
    }
  }

  void _printBoxedInfo(Map<dynamic, dynamic> pubspec, CliLogger logger) async {
    const boxWidth = 78;
    
    // Project Information Section
    final projectLines = _buildProjectInfoLines(pubspec);
    _printBox('📋 PROJECT INFORMATION', projectLines, boxWidth, logger);
    
    print(''); // Spacing between boxes
    
    // Jetleaf Framework Section
    final jetleafLines = await _buildJetleafInfoLines(pubspec, logger);
    _printBox('🚀 JETLEAF FRAMEWORK', jetleafLines, boxWidth, logger);
  }

  List<String> _buildProjectInfoLines(Map<dynamic, dynamic> pubspec) {
    final lines = <String>[];
    
    _addField(lines, 'Name', pubspec['name']);
    _addField(lines, 'Description', pubspec['description']);
    _addField(lines, 'Version', pubspec['version']);
    _addField(lines, 'Homepage', pubspec['homepage']);
    _addField(lines, 'Repository', pubspec['repository']);
    _addField(lines, 'Issue Tracker', pubspec['issue_tracker']);
    _addField(lines, 'Documentation', pubspec['documentation']);
    
    return lines;
  }

  Future<List<String>> _buildJetleafInfoLines(Map<dynamic, dynamic> pubspec, CliLogger logger) async {
    final lines = <String>[];
    
    final dependencies = pubspec['dependencies'] ?? {};
    final devDependencies = pubspec['dev_dependencies'] ?? {};
    final jetleafVersion = dependencies['jetleaf'] ?? devDependencies['jetleaf'];
    
    if (jetleafVersion != null) {
      _addField(lines, 'Version in pubspec', jetleafVersion.toString());
      
      final installedVersion = await getRunningVersion();
      if (installedVersion.notEqualsIgnoreCase("unknown")) {
        _addField(lines, 'Installed version', installedVersion);
      }
    } else {
      lines.add('Jetleaf not found in dependencies');
    }
    
    // Check for other Jetleaf packages
    final jetleafPackages = _findJetleafPackages(dependencies, devDependencies);
    if (jetleafPackages.isNotEmpty) {
      lines.add('');
      lines.add('Other Jetleaf packages:');
      for (final package in jetleafPackages) {
        lines.add('  • $package');
      }
    }
    
    return lines;
  }

  void _addField(List<String> lines, String label, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      lines.add('${label.padRight(18)}: $value');
    }
  }

  void _printBox(String title, List<String> content, int boxWidth, CliLogger logger) {
    final border = '┌${'─' * (boxWidth - 2)}┐';
    final emptyLine = '│${' ' * (boxWidth - 2)}│';
    final bottomBorder = '└${'─' * (boxWidth - 2)}┘';
    
    print(border);
    print('│ ${title.padRight(boxWidth - 4)} │');
    print(emptyLine);
    
    if (content.isEmpty) {
      print('│ ${'No information available'.padRight(boxWidth - 4)} │');
    } else {
      for (final line in content) {
        // Handle multi-line content by wrapping long lines
        final wrappedLines = _preserveWrap(line, boxWidth - 6);
        for (final wrappedLine in wrappedLines) {
          print('│   ${wrappedLine.padRight(boxWidth - 6)} │');
        }
      }
    }
    
    print(bottomBorder);
  }

  List<String> _findJetleafPackages(Map<dynamic, dynamic> dependencies, Map<dynamic, dynamic> devDependencies) {
    final allDeps = {...dependencies, ...devDependencies};
    return allDeps.keys
        .where((key) => key.toString().contains('jetleaf') && key != 'jetleaf')
        .map((key) => '$key: ${allDeps[key]}')
        .toList();
  }
}