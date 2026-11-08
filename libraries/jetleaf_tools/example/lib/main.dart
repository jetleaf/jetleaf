// ignore_for_file: avoid_print, implementation_imports

import 'dart:io';

import 'package:jetleaf_tools/jetleaf_tools.dart';
import 'package:jetleaf_tools/src/cache/indexer/declaration_builder.dart';
import 'package:jetleaf_tools/src/cache/indexer/file_discovery.dart';

// ============================================================================
// 1. SAMPLE TARGET FOR RUNTIME EXECUTOR
// ============================================================================

class OrderProcessor {
  final String region;
  int processedCount = 0;

  OrderProcessor({this.region = 'US-EAST'});

  String processOrder(String orderId, double amount) {
    processedCount++;
    return 'Order #$orderId for \$$amount processed in region $region';
  }
}

// ============================================================================
// 2. MAIN ENTRYPOINT: BUILD & TOOLING DEMO
// ============================================================================

void main() async {
  print('========================================================');
  print('  🛠️  Jetleaf Tools 1.0.0 Feature Showcase');
  print('========================================================');

  // --- A. AST Declaration Analysis ---
  print('\n[1] AST Codebase Analysis (DeclarationBuilder):');
  final tempDir = Directory.systemTemp.createTempSync('jetleaf_tools_demo_');
  final libDir = Directory('${tempDir.path}/lib')..createSync(recursive: true);

  try {
    // Generate a sample Dart source file for static indexing
    final sampleFile = File('${libDir.path}/service.dart');
    sampleFile.writeAsStringSync('''
library demo.service;

abstract class BaseEntity {
  final String id;
  BaseEntity(this.id);
}

class InvoiceService extends BaseEntity {
  final String taxAuthority;
  int invoiceCount = 0;

  InvoiceService(String id, {this.taxAuthority = "IRS"}) : super(id);

  bool issueInvoice(String client, double total) {
    invoiceCount++;
    return total > 0;
  }
}
''');

    // Discover files
    final discovery = FileDiscovery(tempDir);
    final files = await discovery.discover(
      skipTests: true,
      packagesToExclude: [],
      packagesToScan: [],
      filesToExclude: [],
    );

    print('  Discovered ${files.length} source file(s) for indexing.');

    // Build declarations using the AST analyzer
    final builder = DeclarationBuilder();
    final declarations = await builder.build(
      files: files,
      packageName: 'demo_app',
    );

    print('  Extracted ${declarations.length} class component(s):');
    for (final decl in declarations) {
      print('    - Class: ${decl.getName()}');
      print('      Supertype: ${decl.getSuperClass()?.getName() ?? "Object"}');
      print('      Constructors (${decl.getConstructors().length}):');
      for (final ctor in decl.getConstructors()) {
        final ctorName = ctor.getName().isEmpty ? '(default)' : ctor.getName();
        final params = ctor.getParameters().map((p) => '${p.getType()} ${p.getName()}').join(', ');
        print('        • $ctorName($params)');
      }
      print('      Methods (${decl.getMethods().length}):');
      for (final method in decl.getMethods()) {
        print('        • ${method.getReturnType()} ${method.getName()}()');
      }
      print('      Fields (${decl.getFields().length}):');
      for (final field in decl.getFields()) {
        print('        • ${field.getType()} ${field.getName()}');
      }
    }

    // --- B. Runtime Manifest Generation ---
    print('\n[2] Runtime Manifest Serialization:');
    final manifest = RuntimeManifest(
      fingerprint: 'demo_fingerprint_hash_abc123',
      forTests: false,
      treeShakingEnabled: true,
      generatedAt: DateTime.now().toUtc(),
      componentQualifiedNames: declarations.map((d) => d.getName()).toList(),
      libraryUris: ['package:demo_app/service.dart'],
      packageNames: ['demo_app'],
      assetPaths: [],
      subclassIndex: [],
      annotatedMethods: [],
      runtimeHints: [],
    );
    print('  Manifest generated with ${manifest.componentQualifiedNames.length} components.');
    print('  Serialized JSON summary:\n  ${manifest.toJson()}');

    // --- C. AOT Runtime Executor Dispatch ---
    print('\n[3] AOT Runtime Executor (Zero-Reflection Dispatch):');

    // Register AOT constructor factory
    AotRuntimeExecutor.registerNamedConstructor('OrderProcessor', ([argument]) {
      final named = argument?.getNamedArguments() ?? {};
      final region = named['region'] as String? ?? 'US-WEST';
      return OrderProcessor(region: region);
    });

    // Register AOT method invoker
    AotRuntimeExecutor.registerMethod('OrderProcessor.processOrder', (inst, argument) {
      final pos = argument.getPositionalArguments();
      final processor = inst as OrderProcessor;
      return processor.processOrder(pos[0] as String, (pos[1] as num).toDouble());
    });

    // Register AOT field getter
    AotRuntimeExecutor.registerFieldGetter('OrderProcessor.processedCount', (inst) {
      return (inst as OrderProcessor).processedCount;
    });

    // Instantiate via AotRuntimeExecutor
    final instance = AotRuntimeExecutor.constructByName(
      'OrderProcessor',
      ExecutableArgument.unmodified({'region': 'EU-CENTRAL'}, const []),
    ) as OrderProcessor;

    print('  Instantiated: OrderProcessor(region: ${instance.region})');

    // Invoke method via executor
    final executor = AotRuntimeExecutor(DefaultRuntimeHintDescriptor());
    final result = executor.invokeMethod(
      instance,
      'processOrder',
      ExecutableArgument.unmodified(const {}, ['ORD-9901', 450.75]),
    );

    print('  Invoked processOrder: "$result"');

    final count = executor.getValue(instance, 'processedCount');
    print('  Field getValue (processedCount): $count');

    print('\n========================================================');
    print('  ✅ All Jetleaf Tools operations executed successfully!');
    print('========================================================');
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
