// ignore_for_file: invalid_export_of_internal_element

/// 📜 **Jetleaf Declarations Subsystem**
///
/// This library provides the runtime declaration models representing Dart classes,
/// methods, constructors, fields, parameters, and annotations within the Jetleaf
/// mirrorless reflection and AOT code generation pipeline.
///
/// ---
///
/// ## 🌳 Declaration Structural Tree
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     ClassDeclaration                        │
/// ├─────────────────────────────────────────────────────────────┤
/// │ ├── Constructors:     List<ConstructorDeclaration>          │
/// │ ├── Methods:          List<MethodDeclaration>               │
/// │ ├── Fields:           List<FieldDeclaration>                │
/// │ ├── Annotations:      List<AnnotationDeclaration>           │
/// │ ├── SuperClass:       LinkDeclaration?                      │
/// │ ├── Interfaces:       List<LinkDeclaration>                 │
/// │ └── Mixins:           List<LinkDeclaration>                 │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏛️ Type Declarations
/// - [ClassDeclaration] — complete reflective metadata model for a Dart class.
/// - [EnumDeclaration] — metadata model for Dart enums and enhanced enum entries.
/// - [MixinDeclaration] — metadata model for Dart mixins.
/// - [RecordDeclaration] — metadata model for Dart records.
///
/// ### ⚙️ Member Declarations
/// - [ConstructorDeclaration] — reflective model for default, named, and factory constructors.
/// - [MethodDeclaration] — reflective model for static and instance methods.
/// - [FieldDeclaration] — reflective model for instance and static fields with getters/setters.
/// - [ParameterDeclaration] — reflective model for positional, named, required, and optional parameters.
/// - [AnnotationDeclaration] — reflective model for attached annotations and metadata arguments.
///
/// ### 🔗 Linkages & Packages
/// - [LinkDeclaration] — lazy reference link between type references and declaration targets.
/// - [Package] — package descriptor representing package boundaries and versions.
/// - [Asset] — non-source asset file descriptor.
///
/// ---
///
/// ## 🎯 Usage Example: Inspecting Class Declarations
///
/// ```dart
/// import 'package:jetleaf_tools/declaration.dart';
/// import 'package:jetleaf_tools/jetleaf_tools.dart';
///
/// void inspectComponent(ClassDeclaration decl) {
///   print('Class: ${decl.getName()} (Package: ${decl.getPackage().getName()})');
///
///   // Inspect constructors
///   for (final ctor in decl.getConstructors()) {
///     final name = ctor.getName().isEmpty ? '(default)' : ctor.getName();
///     print('  Constructor: $name');
///     for (final param in ctor.getParameters()) {
///       print('    - ${param.getType()} ${param.getName()} (Required: ${param.getIsRequired()})');
///     }
///   }
///
///   // Inspect methods
///   for (final method in decl.getMethods()) {
///     print('  Method: ${method.getReturnType()} ${method.getName()}()');
///   }
/// }
/// ```
library;

export 'src/runtime/declaration/declaration.dart';