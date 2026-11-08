part of 'local_thread.dart';

/// {@template thread_local_key}
/// A unique key used to identify a specific [DartThreadLocal] instance
/// within a Dart [Zone]. Each [DartThreadLocal] gets its own unique ID.
/// {@endtemplate}
@internal
class LocalThreadKey {
  /// The unique integer ID for this key.
  final int id;
  LocalThreadKey._(this.id); // Private constructor

  static int _nextId = 0; // Counter for generating unique IDs

  /// Generates a new unique [LocalThreadKey].
  static LocalThreadKey generate() => LocalThreadKey._(_nextId++);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalThreadKey &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '_ThreadLocalKey(id: $id)';
}