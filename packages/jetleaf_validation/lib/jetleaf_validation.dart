// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// ✅ **Jetleaf Validation Library**
///
/// This library provides a comprehensive framework for validating data,
/// method inputs, and application state in Jetleaf applications. It includes:
/// - declarative validation via annotations  
/// - reusable constraint validators  
/// - validation factories and executors  
/// - exception handling for validation failures  
/// - auto-configuration for seamless integration
///
///
/// ## 🔑 Key Concepts
///
/// ### 📝 Annotations
/// - `annotations.dart` — provides declarative validation annotations
///   such as `@NotNull`, `@Min`, `@Max`, and custom constraints.
///
///
/// ### ⚙ Core Validation Infrastructure
/// - `AbstractExecutableValidator` — base class for validators that can
///   execute validation logic against methods or parameters  
/// - `ValidationFactory` — factory for creating validator instances  
/// - `ValidationAutoConfiguration` — sets up default validation beans
///
///
/// ### 🧱 Base Utilities
/// - `base.dart` — foundational classes and helpers for validation operations  
/// - `constraint_validators.dart` — built-in reusable constraint implementations
///
///
/// ### ⚠ Exception Handling
/// - `exceptions.dart` — contains framework exceptions for validation
///   failures and illegal operations
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to add validation support to your application:
/// ```dart
/// import 'package:jetleaf_validation/jetleaf_validation.dart';
///
/// @NotNull
/// String username;
///
/// final factory = ValidationFactory();
/// factory.validate(user);
/// ```
///
/// Supports annotation-driven validation, programmatic validation, and
/// custom constraint validators.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'src/annotations.dart';
export 'src/abstract_executable_validator.dart';
export 'src/base.dart';
export 'src/constraint_validators.dart';
export 'src/exceptions.dart';
export 'src/validation_auto_configuration.dart';
export 'src/validation_factory.dart';