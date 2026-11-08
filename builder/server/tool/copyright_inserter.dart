// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';

void main(List<String> args) async {
  final dir = Directory.current;
  final year = DateTime.now().year;
  final header = '''
// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © $year Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

''';

  final dartFiles = await dir
      .list(recursive: true)
      .where((f) =>
          f is File &&
          f.path.endsWith('.dart') &&
          !f.path.contains('/.dart_tool/') &&
          !f.path.contains('/build/'))
      .cast<File>()
      .toList();

  for (final file in dartFiles) {
    final content = await file.readAsString();
    if (!content.startsWith('''
// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
''')) {
      final newContent = header + content;
      await file.writeAsString(newContent);
      print('✔ Added header to: ${file.path}');
    }
  }

  print('\n✅ License headers added.');
}