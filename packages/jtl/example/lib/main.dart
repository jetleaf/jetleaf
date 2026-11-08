// ignore_for_file: avoid_print

import 'package:jetleaf_core/lang.dart';
import 'package:jtl/jtl.dart';

void main() {
  print('========================================================');
  print('  🍃 JTL (Jetleaf Template Language) 2.0.0 Showcase');
  print('========================================================\n');

  final jtl = JtlFactory();

  // 1. Simple Variable Interpolation with HTML escaping
  print('[1] Simple Variable Interpolation:');
  const templateHtml = '''
<!DOCTYPE html>
<html>
<head><title>{{title}}</title></head>
<body>
  <h1>Welcome, {{user.name}}!</h1>
  <p>Email: {{user.email}}</p>
  <p>Escaped Content: {{unsafeHtml}}</p>
</body>
</html>''';

  final template = JtlTemplate(
    'views/welcome.html',
    {
      'title': 'JTL Showcase',
      'user': {
        'name': 'Alice Johnson',
        'email': 'alice@jetleaf.dev',
      },
      'unsafeHtml': '<script>alert("XSS")</script>',
    },
  );

  final asset = AssetResource(templateHtml);
  final rendered = jtl.render(template, asset);

  print('Rendered Output:\n${rendered.getRenderedContent()}');

  // 2. Custom Filter Registration
  print('[2] Custom Filter Registry:');
  final filters = jtl.getFilterRegistry();
  filters.registerFilter('shout', (val) => '${val.toString().toUpperCase()}!!!');
  final shoutFn = filters.getFilter('shout');
  print('Registered filter "shout" -> result: ${shoutFn?.call('hello world')}');

  print('\n========================================================');
  print('  ✅ JTL Example executed successfully!');
  print('========================================================');
}