/// The Jetleaf Framework provides core runtime primitives for building
/// backend applications using **Hapnium**, including:
///
/// - application argument parsing
/// - environment and configuration management
/// - profile-based configuration
/// - framework-level exception handling
///
/// This library acts as the public entry point and re-exports the primary
/// Jetleaf APIs so they can be consumed directly.
///
///
/// ## 🔧 Key Features
///
/// - Centralized environment abstraction (`Environment`)
/// - Global environment resolution for runtime configuration
/// - Multiple configuration property sources
/// - Built-in support for application arguments
/// - Profile activation (e.g., `dev`, `prod`, `test`)
///
///
/// ## 📦 Exports Overview
///
/// ### ✅ Argument Handling
/// - `ApplicationArguments` — runtime arguments wrapper
/// - `DefaultApplicationArguments` — standard implementation
///
/// ### 🌍 Environment & Configuration
/// - `Environment` — core environment contract
/// - `AbstractEnvironment` — base implementation
/// - `ConfigurationPropertySource` — config value provider interface
/// - `GlobalEnvironment` — shared global environment instance
/// - `env` — convenience accessor for the active environment
///
/// ### 🏷 Profiles
/// - `profiles` — profile utilities and runtime activation
///
/// ### ⚠️ Exceptions
/// - Jetleaf framework-level exception definitions
///
///
/// ## 🔐 Licensing
///
/// This source is part of the **Jetleaf Framework** and protected under
/// the Jetleaf license. See the `LICENSE` file for terms.
library;

export 'src/argument/application_arguments.dart';
export 'src/argument/default_application_arguments.dart';

export 'src/core/environment.dart';
export 'src/core/abstract_environment.dart';
export 'src/core/configuration_property_source.dart';
export 'src/core/global_environment.dart';
export 'src/core/env.dart';

export 'src/profiles/profiles.dart';

export 'src/exceptions.dart';