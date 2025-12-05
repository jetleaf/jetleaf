import 'package:jetleaf_env/jetleaf_env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../jet_application.dart';
import '../jet_leaf_version.dart';
import 'abstract_environment_profile_support.dart';

/// Adds support for populating version-related properties into the application
/// environment during startup.
///
/// This abstract base class extends [AbstractEnvironmentProfileSupport] and
/// contributes additional bootstrapping behavior by inserting a dedicated
/// version property source.  
///
/// The version information typically includes:
/// - The **Jetleaf framework version**, sourced from [JetLeafVersion].
/// - The **application's own version**, derived from the package metadata of
///   the supplied application class.
///
/// Subclasses may integrate this into the environment preparation phase to
/// ensure that all version properties are consistently available throughout the
/// application's lifecycle.
abstract class AbstractVersionedSupport extends AbstractEnvironmentProfileSupport {
  /// Registers a property source containing framework and application version
  /// information.
  ///
  /// This method inspects the current [ConfigurableEnvironment] and inserts a
  /// `PropertiesPropertySource` named `"versioned"` containing:
  ///
  /// - **`JetApplication.JETLEAF_VERSION`**  
  ///   Added if not already present. Its value is obtained from
  ///   [JetLeafVersion.getVersion].
  ///
  /// - **`JetApplication.JETLEAF_APPLICATION_VERSION`**  
  ///   Added if not already present. Its value is derived from the version
  ///   metadata of the provided [applicationClass]. If the version cannot be
  ///   resolved, the value defaults to `"unknown"`.
  ///
  /// Existing properties in the environment take precedence and will *not* be
  /// overridden.  
  ///
  /// The property source is appended to the end of the environment’s property
  /// source chain, allowing higher-priority sources to override these values
  /// if needed.
  @protected
  void addVersionedPropertySource(ConfigurableEnvironment environment, Class<Object> applicationClass) {
    final versionContent = <String, Object>{};

    if (environment.getProperty(JetApplication.JETLEAF_VERSION) == null) {
      versionContent[JetApplication.JETLEAF_VERSION] = JetLeafVersion.getVersion();
    }

    if (environment.getProperty(JetApplication.JETLEAF_APPLICATION_VERSION) == null) {
      versionContent[JetApplication.JETLEAF_APPLICATION_VERSION] = applicationClass.getPackage()?.getVersion() ?? "unknown";
    }

    environment.getPropertySources().addLast(PropertiesPropertySource("versioned", versionContent));
  }
}