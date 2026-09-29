import 'package:test/test.dart';
import 'package:jetleaf_build/cache.dart';
import 'package:jetleaf_build/src/runtime/declaration/declaration.dart';
import 'package:jetleaf_build/src/exceptions.dart';

/// Helper to build a StandardClassDeclaration for testing.
StandardClassDeclaration _makeClass({
  required String name,
  String? qualifiedName,
  bool isPublic = true,
  bool isAbstract = false,
  bool isMixin = false,
  bool isEnum = false,
  List<ConstructorDeclaration> constructors = const [],
  List<FieldDeclaration> fields = const [],
  List<MethodDeclaration> methods = const [],
  List<AnnotationDeclaration> annotations = const [],
  List<LinkDeclaration> interfaces = const [],
  List<LinkDeclaration> mixins = const [],
  LinkDeclaration? superClass,
}) {
  if (isEnum) {
    return StandardEnumDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: StandardLibraryDeclaration(
        uri: 'test',
        name: 'test',
        isPublic: true,
        isSynthetic: false,
        parentPackage: MaterialPackage(
          name: 'test',
          version: '0.0.0',
          isRootPackage: true,
          filePath: null,
          rootUri: null,
          dependencies: const [],
          devDependencies: const [],
          jetleafDependencies: const [],
        ),
      ),
      values: (annotations).whereType<EnumFieldDeclaration>().toList(),
    );
  }
  return StandardClassDeclaration(
    name: name,
    type: Object,
    isPublic: isPublic,
    isSynthetic: false,
    library: StandardLibraryDeclaration(
      uri: 'test',
      name: 'test',
      isPublic: true,
      isSynthetic: false,
      parentPackage: MaterialPackage(
        name: 'test',
        version: '0.0.0',
        isRootPackage: true,
        filePath: null,
        rootUri: null,
        dependencies: const [],
        devDependencies: const [],
        jetleafDependencies: const [],
      ),
    ),
    qualifiedName: qualifiedName ?? 'test.$name',
    simpleName: name,
    constructors: constructors,
    fields: fields,
    methods: methods,
    superClass: superClass,
    interfaces: interfaces,
    mixins: mixins,
    annotations: annotations,
    isAbstract: isAbstract,
    isMixin: isMixin,
  );
}

void main() {
  group('CacheSerializer', () {
    test('round-trip serialization preserves basic class data', () {
      final components = [
        _makeClass(name: 'UserService'),
        _makeClass(name: 'Config'),
      ];

      final fileEntries = {
        'lib/services/user_service.dart': 1719590000000,
        'lib/config.dart': 1719590002000,
      };

      // Serialize
      final bytes = CacheSerializer.serialize(components, fileEntries);

      // Deserialize
      final result = CacheSerializer.deserialize(bytes);

      // Verify file entries
      expect(result.fileEntries.length, equals(2));
      expect(result.fileEntries['lib/services/user_service.dart'], equals(1719590000000));

      // Verify components
      expect(result.components.length, equals(2));
      expect(result.components[0].getName(), equals('UserService'));
      expect(result.components[1].getName(), equals('Config'));
    });

    test('handles empty components list', () {
      final bytes = CacheSerializer.serialize([], {});
      final result = CacheSerializer.deserialize(bytes);
      expect(result.components, isEmpty);
      expect(result.fileEntries, isEmpty);
    });

    test('handles components with no annotations or parameters', () {
      final components = [
        _makeClass(name: 'Simple'),
      ];

      final bytes = CacheSerializer.serialize(components, {});
      final result = CacheSerializer.deserialize(bytes);
      expect(result.components.length, equals(1));
      expect(result.components[0].getName(), equals('Simple'));
    });

    test('round-trips subclasses index', () {
      final components = [_makeClass(name: 'A')];
      final subclasses = {
        'Animal': ['Dog', 'Cat'],
        'Shape': ['Circle'],
      };

      final bytes = CacheSerializer.serialize(components, {}, subclasses: subclasses);
      final result = CacheSerializer.deserialize(bytes);

      expect(result.subclasses['Animal'], equals(['Dog', 'Cat']));
      expect(result.subclasses['Shape'], equals(['Circle']));
    });

    test('round-trips annotated methods index', () {
      final components = [_makeClass(name: 'A')];
      final annotatedMethods = {
        'Route': [
          {'class': 'UserController', 'method': 'get', 'uri': 'package:app/main.dart'},
        ],
      };

      final bytes = CacheSerializer.serialize(components, {}, annotatedMethods: annotatedMethods);
      final result = CacheSerializer.deserialize(bytes);

      expect(result.annotatedMethods['Route']!.length, equals(1));
      expect(result.annotatedMethods['Route']![0]['class'], equals('UserController'));
    });

    test('rejects version 1 cache', () {
      // Manually build a v1 cache header to verify rejection
      final builder = BinaryBuilder();
      builder.writeBytes([0x4A, 0x4C, 0x42, 0x43]); // magic
      builder.writeUint8(1); // version 1
      builder.writeUint64(0);
      builder.writeUint32(0); // file count
      builder.writeUint32(0); // string count
      builder.writeUint32(0); // component count

      expect(
        () => CacheSerializer.deserialize(builder.toBytes()),
        throwsA(isA<BuildableCacheException>()),
      );
    });

    test('round-trips mixed class, enum and mixin components in order',
        () {
      // Regression: enums/mixins serialize their full class layout plus
      // kind extras. Reading everything back as a bare class desynced the
      // stream at the first non-class entry, corrupting all followers.
      // The enum sits in the middle on purpose: followers must survive.
      final components = [
        _makeClass(name: 'First'),
        _makeEnum(name: 'Status'),
        _makeMixin(name: 'Timestamped'),
        _makeClass(name: 'Last'),
      ];

      final bytes = CacheSerializer.serialize(components, {});
      final result = CacheSerializer.deserialize(bytes);

      expect(result.components.length, equals(4));
      expect(result.components[0].getName(), equals('First'));
      expect(result.components[0].getKind(), equals(TypeKind.classType));
      expect(result.components[1].getName(), equals('Status'));
      expect(result.components[1].getKind(), equals(TypeKind.enumType));
      expect(result.components[2].getName(), equals('Timestamped'));
      expect(result.components[2].getKind(), equals(TypeKind.mixinType));
      expect(result.components[3].getName(), equals('Last'));
      expect(result.components[3].getKind(), equals(TypeKind.classType));
    });

    test('round-trips a class with an explicit constructor', () {
      // Regression: the constructor parent class is a link on write but
      // was read back as a full declaration, desyncing every component
      // after the first class with an explicit constructor.
      final parent = StandardLinkDeclaration(
        name: 'Service',
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: 'Service',
      );
      final components = [
        _makeClass(name: 'Svc', constructors: [
          StandardConstructorDeclaration(
            name: '',
            type: Object,
            isPublic: true,
            isSynthetic: false,
            parentClass: parent,
            parameters: [
              StandardParameterDeclaration(
                name: 'dep',
                type: Object,
                typeDeclaration: parent,
                isPublic: true,
                isSynthetic: false,
                index: 0,
              ),
            ],
          ),
        ]),
        _makeClass(name: 'After'),
      ];

      final bytes = CacheSerializer.serialize(components, {});
      final result = CacheSerializer.deserialize(bytes);

      expect(result.components.length, equals(2));
      expect(result.components[0].getName(), equals('Svc'));
      expect(result.components[0].getConstructors(), hasLength(1));
      expect(
          result.components[0].getConstructors().single.getParentClass()?.getName(),
          equals('Service'));
      expect(result.components[1].getName(), equals('After'));
    });
  });
}

/// Helper to build a [StandardEnumDeclaration] for testing.
StandardEnumDeclaration _makeEnum({required String name}) {
  return StandardEnumDeclaration(
    name: name,
    type: Object,
    isPublic: true,
    isSynthetic: false,
    library: StandardLibraryDeclaration(
      uri: 'test',
      name: 'test',
      isPublic: true,
      isSynthetic: false,
      parentPackage: MaterialPackage(
        name: 'test',
        version: '0.0.0',
        isRootPackage: true,
        filePath: null,
        rootUri: null,
        dependencies: const [],
        devDependencies: const [],
        jetleafDependencies: const [],
      ),
    ),
    values: const [],
  );
}

/// Helper to build a [StandardMixinDeclaration] for testing.
StandardMixinDeclaration _makeMixin({required String name}) {
  return StandardMixinDeclaration(
    name: name,
    type: Object,
    isPublic: true,
    isSynthetic: false,
    library: StandardLibraryDeclaration(
      uri: 'test',
      name: 'test',
      isPublic: true,
      isSynthetic: false,
      parentPackage: MaterialPackage(
        name: 'test',
        version: '0.0.0',
        isRootPackage: true,
        filePath: null,
        rootUri: null,
        dependencies: const [],
        devDependencies: const [],
        jetleafDependencies: const [],
      ),
    ),
  );
}
