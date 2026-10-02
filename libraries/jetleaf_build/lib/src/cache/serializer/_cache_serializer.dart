part of 'cacheable_serializer.dart';

/// Magic bytes identifying a Jetleaf Binary Cache file.
const List<int> _kMagic = [0x4A, 0x4C, 0x42, 0x43]; // "JLBC"

/// Current cache format version.
///
/// v3 adds a per-component kind tag (class/enum/mixin). v2 bins are
/// rejected with a clear message: every v2 bin containing an enum or
/// mixin is unloadable anyway (the reader consumed all components as
/// bare classes, desyncing the stream at the first non-class entry).
const int _kVersion = 3;

/// Component kind tags (written before each component).
const int _kKindClass = 0;
const int _kKindEnum = 1;
const int _kKindMixin = 2;

/// {@template cache_serializer_impl}
/// Private implementation of [CacheableSerializer].
/// {@endtemplate}
final class _CacheableSerializer extends CacheableSerializer {
  /// {@macro cache_serializer_impl}
  const _CacheableSerializer._() : super._();

  @override
  Uint8List serialize(
    List<ClassDeclaration> components,
    Map<String, int> fileEntries, {
    List<Asset> assets = const [],
    List<Package> packages = const [],
    List<IndexedLibraryMeta> libraries = const [],
    Map<String, List<String>> subclasses = const {},
    Map<String, List<Map<String, String>>> annotatedMethods = const {},
  }) {
    final builder = BinaryBuilder();

    // Header
    builder.writeBytes(_kMagic);
    builder.writeUint8(_kVersion);
    builder.writeUint64(DateTime.now().millisecondsSinceEpoch);

    // File entries
    builder.writeUint32(fileEntries.length);
    for (final entry in fileEntries.entries) {
      builder.writeString(entry.key);
      builder.writeUint64(entry.value);
    }

    // Components — kind-tagged: enums and mixins serialize their full
    // class layout plus kind-specific extras, so the reader must know
    // which extras follow (reading everything as a bare class desyncs
    // the stream at the first non-class component).
    builder.writeUint32(components.length);
    for (final decl in components) {
      builder.writeUint8(_componentKindTag(decl));
      decl.serialize(builder);
    }

    // Assets — delegate to Asset serialize
    builder.writeUint32(assets.length);
    for (final asset in assets) {
      asset.serialize(builder);
    }

    // Packages — delegate to Package serialize
    builder.writeUint32(packages.length);
    for (final pkg in packages) {
      pkg.serialize(builder);
    }

    // Libraries
    builder.writeUint32(libraries.length);
    for (final l in libraries) {
      builder.writeString(l.uri);
      builder.writeString(l.packageName);
      builder.writeBool(l.isSdk);
    }

    // Subclasses
    builder.writeUint32(subclasses.length);
    for (final entry in subclasses.entries) {
      builder.writeString(entry.key);
      builder.writeUint32(entry.value.length);
      for (final child in entry.value) {
        builder.writeString(child);
      }
    }

    // Annotated methods
    builder.writeUint32(annotatedMethods.length);
    for (final entry in annotatedMethods.entries) {
      builder.writeString(entry.key);
      builder.writeUint32(entry.value.length);
      for (final method in entry.value) {
        builder.writeString(method['class'] ?? '');
        builder.writeString(method['method'] ?? '');
        builder.writeString(method['uri'] ?? '');
      }
    }

    return builder.toBytes();
  }

  @override
  CacheDeserializationResult deserialize(Uint8List data) {
    final reader = BinaryReader(data);

    final magic = reader.readBytes(4);
    if (magic[0] != _kMagic[0] ||
        magic[1] != _kMagic[1] ||
        magic[2] != _kMagic[2] ||
        magic[3] != _kMagic[3]) {
      throw BuildableCacheException('Invalid cache file: bad magic bytes');
    }

    final version = reader.readUint8();
    if (version == 1) {
      throw BuildableCacheException(
        'Cache version 1 is no longer supported. '
        'Please run a clean build to regenerate the cache.',
      );
    }
    if (version != _kVersion) {
      throw BuildableCacheException('Unsupported cache version: $version (expected $_kVersion)');
    }

    final timestamp = reader.readUint64();

    final fileCount = reader.readUint32();
    final fileEntries = <String, int>{};
    for (var i = 0; i < fileCount; i++) {
      final path = reader.readString();
      final mtime = reader.readUint64();
      fileEntries[path] = mtime;
    }

    // Components — kind-tagged dispatch (see writer above).
    final componentCount = reader.readUint32();
    final components = List<ClassDeclaration>.generate(
      componentCount,
      (_) => _readComponent(reader),
    );

    // Assets — delegate to Asset deserialize
    final assetCount = reader.readUint32();
    final assets = List<Asset>.generate(
      assetCount,
      (_) => Asset.deserialize(reader),
    );

    // Packages — delegate to Package deserialize
    final packageCount = reader.readUint32();
    final packages = List<Package>.generate(
      packageCount,
      (_) => Package.deserialize(reader),
    );

    // Libraries
    final libraryCount = reader.readUint32();
    final libraries = List<IndexedLibraryMeta>.generate(libraryCount, (_) {
      return IndexedLibraryMeta(
        uri: reader.readString(),
        packageName: reader.readString(),
        isSdk: reader.readBool(),
      );
    });

    // Subclasses
    final subclassCount = reader.readUint32();
    final subclasses = <String, List<String>>{};
    for (var i = 0; i < subclassCount; i++) {
      final parent = reader.readString();
      final childCount = reader.readUint32();
      subclasses[parent] = List<String>.generate(childCount, (_) => reader.readString());
    }

    // Annotated methods
    final annotatedCount = reader.readUint32();
    final annotatedMethods = <String, List<Map<String, String>>>{};
    for (var i = 0; i < annotatedCount; i++) {
      final annotation = reader.readString();
      final methodCount = reader.readUint32();
      annotatedMethods[annotation] = List<Map<String, String>>.generate(methodCount, (_) {
        return {
          'class': reader.readString(),
          'method': reader.readString(),
          'uri': reader.readString(),
        };
      });
    }

    return CacheDeserializationResult(
      components: components,
      fileEntries: fileEntries,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      assets: assets,
      packages: packages,
      libraries: libraries,
      subclasses: subclasses,
      annotatedMethods: annotatedMethods,
    );
  }

  /// Maps a component to its kind tag (mirrors [TypeKind]).
  ///
  /// **Parameters:**
  /// - [decl]: component to classify.
  ///
  /// **Returns:** [_kKindEnum], [_kKindMixin], or [_kKindClass].
  static int _componentKindTag(ClassDeclaration decl) {
    final kind = decl.getKind();
    if (kind == TypeKind.enumType) return _kKindEnum;
    if (kind == TypeKind.mixinType) return _kKindMixin;
    return _kKindClass;
  }

  /// Reads one kind-tagged component.
  ///
  /// Class layout first in every case (enums/mixins serialize their full
  /// class shape via `super`), then kind-specific extras, rebuilt into
  /// the faithful declaration type with members preserved.
  ///
  /// **Parameters:**
  /// - [reader]: positioned at the kind tag.
  ///
  /// **Returns:** the reconstructed component.
  static ClassDeclaration _readComponent(BinaryReader reader) {
    final tag = reader.readUint8();
    final base = StandardClassDeclaration.deserialize(reader);
    switch (tag) {
      case _kKindEnum:
        final name = reader.readString();
        final typeName = reader.readString();
        final valueCount = reader.readUint16();
        final values = List.generate(
            valueCount,
            (_) => StandardEnumFieldDeclaration.deserialize(reader));
        return StandardEnumDeclaration(
          name: name,
          type: StandardDeclaration.resolveType(typeName),
          isPublic: base.getIsPublic(),
          isSynthetic: base.getIsSynthetic(),
          library: StandardLibraryDeclaration.empty(),
          qualifiedName: base.getQualifiedName(),
          constructors: base.getConstructors(),
          fields: base.getFields(),
          methods: base.getMethods(),
          superClass: base.getSuperClass(),
          interfaces: base.getInterfaces(),
          mixins: base.getMixins(),
          typeArguments: base.getTypeArguments(),
          annotations: base.getAnnotations(),
          values: values,
        );
      case _kKindMixin:
        final name = reader.readString();
        final typeName = reader.readString();
        final constraintCount = reader.readUint16();
        final constraints = List.generate(
            constraintCount,
            (_) => StandardLinkDeclaration.deserialize(reader));
        return StandardMixinDeclaration(
          name: name,
          type: StandardDeclaration.resolveType(typeName),
          isPublic: base.getIsPublic(),
          isSynthetic: base.getIsSynthetic(),
          library: StandardLibraryDeclaration.empty(),
          qualifiedName: base.getQualifiedName(),
          constructors: base.getConstructors(),
          fields: base.getFields(),
          methods: base.getMethods(),
          superClass: base.getSuperClass(),
          interfaces: base.getInterfaces(),
          mixins: base.getMixins(),
          typeArguments: base.getTypeArguments(),
          annotations: base.getAnnotations(),
          constraints: constraints,
        );
      default:
        return base;
    }
  }
}
