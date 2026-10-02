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

/// Enumerates all **token types** that an [XmlParser] can encounter during
/// XML parsing.
///
/// ### Example
/// ```dart
/// if (parser.getCurrentToken() == XmlToken.TEXT) {
///   print('Text: ${parser.getText()}');
/// }
/// ```
enum XmlToken {
  /// Start of an XML element (`<tag>`).
  START_ELEMENT,

  /// End of an XML element (`</tag>`).
  END_ELEMENT,

  /// Text content between elements.
  TEXT,

  /// CDATA section (`<![CDATA[...]]>`).
  CDATA,

  /// Processing instruction (`<?...?>`).
  PROCESSING_INSTRUCTION,

  /// XML comment (`<!-- ... -->`).
  COMMENT,

  /// Entity reference.
  ENTITY_REFERENCE,

  /// End of document.
  END_DOCUMENT,
}