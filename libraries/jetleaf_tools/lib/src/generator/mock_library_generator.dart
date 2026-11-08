import 'default_library_generator.dart';

/// {@template mock_library_generator}
/// A mock implementation of [LibraryGenerator].
/// {@endtemplate}
base class MockLibraryGenerator extends DefaultLibraryGenerator {
  /// {@macro mock_library_generator}
  MockLibraryGenerator({
    required super.configuration,
    required super.packages,
    super.mirrorSystem,
    super.forceLoadedMirrors,
    super.refresh,
  });
}