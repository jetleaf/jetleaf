import 'dart:typed_data';

import 'package:jetleaf_build/src/cache/serializer/helpers.dart';
import 'package:jtl/jtl.dart';
import 'package:jetleaf_lang/lang.dart';

class TestAssetBuilderImpl implements AssetBuilder {
  final Map<String, String> _templates;

  TestAssetBuilderImpl(this._templates);

  @override
  AssetPathResource build(String template) {
    final content = _templates[template] ?? '';
    final asset = AssetResource(content);
    return _TestAssetPathResourceImpl(content, asset);
  }

  @override
  List<Object?> equalizedProperties() => [_templates];
}

class _TestAssetPathResourceImpl implements AssetPathResource {
  final String _content;
  final Asset _asset;

  _TestAssetPathResourceImpl(this._content, this._asset);

  @override
  bool exists() => true;

  @override
  Asset get([Supplier<Exception>? throwIfNotFound]) => _asset;

  @override
  Asset? tryGet([Supplier<Exception>? orElseThrow]) => _asset;

  @override
  String getResourcePath() => 'test/template.html';

  @override
  bool hasExtension(List<String> exts) => exts.any((e) => e == '.html');

  @override
  String getContentAsString() => _content;

  @override
  Uint8List getContentBytes() => _asset.getContentBytes();

  @override
  String getFileName() => 'test/template.html';

  @override
  String getFilePath() => 'test/template.html';

  @override
  String? getPackageName() => 'test';

  @override
  String getUniqueName() => 'test_template';

  @override
  InputStream getInputStream() => ByteArrayInputStream(getContentBytes());

  @override
  Map<String, Object> toJson() => {'source': _content};

  @override
  List<Object?> equalizedProperties() => [_content];

  @override
  void serialize(BinaryBuilder builder) { }
}

class TestAssetBuilder {
  final Map<String, String> _templates;
  TestAssetBuilder(this._templates);
  AssetBuilder create() => TestAssetBuilderImpl(_templates);
}

Asset TestAsset(String content) => AssetResource(content);

AssetBuilder assetBuilder(Map<String, String> templates) {
  return TestAssetBuilderImpl(templates);
}

SourceCode renderTemplate(
  String templateContent, {
  Map<String, Object?>? attributes,
  TemplateFilterRegistry? filterRegistry,
}) {
  final filters = filterRegistry ?? TemplateFilterRegistry();
  final builder = assetBuilder({'test/template.html': templateContent});
  final renderer = DefaultTemplateRenderer(filters, builder);
  final resolver = DefaultVariableResolver();
  resolver.setVariables(attributes ?? {});
  final context = DefaultTemplateContext(resolver);
  final tmpl = JtlTemplate('test/template.html', attributes ?? {});
  return renderer.render(tmpl, context);
}
