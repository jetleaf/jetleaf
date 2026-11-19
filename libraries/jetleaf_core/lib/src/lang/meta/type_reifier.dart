// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// {@template jetleaf_type_reifier}
/// Runtime type reifier capable of instantiating strongly-typed generic
/// collections (`List<T>`, `Set<T>`, `Iterable<T>`, and `Map<K, V>`) for a
/// specific reified Dart type `T`.
///
/// Because Dart's type system reifies generic type arguments at runtime and
/// enforces covariance checks during `Function.apply` and reflective field
/// assignment, a `List<dynamic>` or `List<Object?>` cannot be passed where a
/// `List<T>` is expected. [TypeReifier] captures the static type parameter `T`
/// inside a compiled generic instance ([StandardTypeReifier]) so the runtime
/// can construct genuine `List<T>`, `Set<T>`, and `Map<K, V>` collections for
/// any registered or reflected type—including user-defined entities, enums,
/// annotations, and nested generic collections.
///
/// ### Double-Dispatch Map Reification
/// To construct a reified `Map<K, V>` for any arbitrary pair of registered
/// types `(K, V)` in $O(N)$ space without $O(N^2)$ pre-registration,
/// [createMapWithValue] uses generic double-dispatch:
/// 1. The key reifier (`TypeReifier` for `K`) invokes
///    `valueReifier.createMapWithKey<K>(entries)` where `K` is bound to its
///    own reified type parameter.
/// 2. The value reifier (`TypeReifier` for `V`) executes `<K, V>{...}` with
///    both `K` and `V` statically bound in scope.
///
/// ### Usage Example
/// ```dart
/// final userReifier = MaterializedLibrary.lookupTypeReifier(name: 'User');
/// final typedList = userReifier?.createList([user1, user2]); // List<User>
///
/// final stringReifier = MaterializedLibrary.lookupTypeReifier(type: String);
/// final typedMap = stringReifier?.createMapWithValue(
///   userReifier!,
///   {'admin': user1},
/// ); // Map<String, User>
/// ```
///
/// ### See Also
/// - [StandardTypeReifier]
/// - [MaterializedLibrary]
/// {@endtemplate}
abstract interface class TypeReifier {
  /// Returns the reified Dart [Type] represented by this reifier.
  Type getType();

  /// Returns the reified `List<T>` (or `List<T?>` when [nullable] is `true`)
  /// [Type] token.
  Type getListType({bool nullable = false});

  /// Returns the reified `Set<T>` (or `Set<T?>` when [nullable] is `true`)
  /// [Type] token.
  Type getSetType({bool nullable = false});

  /// Returns the reified `Iterable<T>` (or `Iterable<T?>` when [nullable] is
  /// `true`) [Type] token.
  Type getIterableType({bool nullable = false});

  /// Returns `true` if [value] is an instance of the reified type `T`.
  bool isInstance(Object? value);

  /// Returns `true` if [value] is already a reified `List<T>` (or `List<T?>`
  /// when [nullable] is `true`).
  bool isListInstance(Object? value, {bool nullable = false});

  /// Returns `true` if [value] is already a reified `Set<T>` (or `Set<T?>`
  /// when [nullable] is `true`).
  bool isSetInstance(Object? value, {bool nullable = false});

  /// Creates a strongly-typed `List<T>` (or `List<T?>` when [nullable] is
  /// `true`) containing [elements].
  List<Object?> createList([Iterable<dynamic>? elements, bool nullable = false]);

  /// Creates a strongly-typed `Set<T>` (or `Set<T?>` when [nullable] is
  /// `true`) containing [elements].
  Set<Object?> createSet([Iterable<dynamic>? elements, bool nullable = false]);

  /// Creates a strongly-typed `Iterable<T>` (or `Iterable<T?>` when [nullable]
  /// is `true`) containing [elements].
  Iterable<Object?> createIterable([Iterable<dynamic>? elements, bool nullable = false]);

  /// Creates a strongly-typed `Map<T, V>` where `T` is this reifier's type
  /// and `V` is the type of [valueReifier].
  Map<Object?, Object?> createMapWithValue(
    TypeReifier valueReifier, [
    Map<dynamic, dynamic>? entries,
    bool nullableValue = false,
  ]);

  /// Second stage of double-dispatch map creation: creates a `Map<K, T>`
  /// (or `Map<K, T?>` when [nullableValue] is `true`) for a caller-supplied
  /// key type [K] and this reifier's value type `T`.
  Map<K, Object?> createMapWithKey<K>([
    Map<dynamic, dynamic>? entries,
    bool nullableValue = false,
  ]);

  /// Returns a [TypeReifier] for `List<T>` (or `List<T?>` when [nullable] is
  /// `true`), enabling nested collection reification such as `List<List<T>>`.
  TypeReifier getListReifier({bool nullable = false});

  /// Returns a [TypeReifier] for `Set<T>` (or `Set<T?>` when [nullable] is
  /// `true`).
  TypeReifier getSetReifier({bool nullable = false});

  /// Returns a [TypeReifier] for `Map<T, V>` where `T` is this reifier's type
  /// and `V` is the type of [valueReifier].
  TypeReifier getMapReifierWithValue(TypeReifier valueReifier, {bool nullableValue = false});

  /// Second stage of double-dispatch map reifier composition: returns a
  /// [TypeReifier] for `Map<K, T>` (or `Map<K, T?>` when [nullableValue] is
  /// `true`).
  TypeReifier getMapReifierWithKey<K>({bool nullableValue = false});
}
