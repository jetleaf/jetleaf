// Regression test: a synthetic Class (emitted by AOT for types from packages
// outside the scanned component set) must not trigger a conversion attempt.
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/src/pod/core/default_listable_pod_factory.dart';
import 'package:test/test.dart';
import '../../lang/meta/test_data.dart' show ensureTestAotRegisteredSync;

/// Builds a synthetic [Class] the way the AOT generator does for an external
/// interface whose declaration is not in the runtime type registry.
Class<Object> syntheticClass(String name) {
  final library = StandardLibraryDeclaration(
    uri: 'package:synthetic/$name.dart',
    name: name,
    isPublic: true,
    isSynthetic: true,
    parentPackage: MaterialPackage(
      name: 'synthetic',
      version: '1.0.0',
      isRootPackage: false,
      filePath: null,
      rootUri: null,
      dependencies: const [],
      devDependencies: const [],
      jetleafDependencies: const [],
    ),
  );
  final declaration = StandardClassDeclaration(
    name: name,
    type: Object,
    library: library,
    isPublic: true,
    isSynthetic: true,
    isAbstract: true,
    isInterface: true,
    qualifiedName: 'package:synthetic/$name.dart.$name',
  );
  return Class<Object>.declared(declaration, ProtectionDomain.current());
}

void main() {
  ensureTestAotRegisteredSync();
  test('synthetic target type returns the pod unchanged', () {
    final factory = DefaultListablePodFactory();

    // This is exactly the shape emitted by AOT for `Pool<void>` from an
    // external package: a synthetic Class with no resolvable hierarchy.
    final synthetic = syntheticClass('ExternalDriverPool');
    expect(synthetic.isSynthetic(), isTrue);

    final instance = Object();
    final result = factory.convertIfNecessary<Object>(
      'pool',
      instance,
      synthetic,
    );

    expect(result, same(instance));
  });
}
