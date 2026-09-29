import 'dart:typed_data';

import '../../exceptions.dart';
import '../../helpers/equals_and_hash_code.dart';
import '../../runtime/declaration/declaration.dart';
import '../models.dart';
import 'helpers.dart';

part '_cache_serializer.dart';

/// {@template cache_serializer}
/// Binary serializer for [ClassDeclaration] and related cache types.
///
/// Uses a compact binary format with string deduplication via a string table.
/// All strings are stored once in a string table and referenced by uint16 index.
/// {@endtemplate}
abstract final class CacheableSerializer with EqualsAndHashCode {
  const CacheableSerializer._();

  /// Serializes a list of [ClassDeclaration] and file entries to a compact binary format.
  Uint8List serialize(
    List<ClassDeclaration> components,
    Map<String, int> fileEntries, {
    List<Asset> assets = const [],
    List<Package> packages = const [],
    List<IndexedLibraryMeta> libraries = const [],
    Map<String, List<String>> subclasses = const {},
    Map<String, List<Map<String, String>>> annotatedMethods = const {},
  });

  /// Deserializes binary data back into a [CacheDeserializationResult].
  CacheDeserializationResult deserialize(Uint8List data);

  @override
  List<Object?> equalizedProperties() => [];
}

/// Singleton instance of [CacheableSerializer].
final CacheableSerializer CacheSerializer = _CacheableSerializer._();
