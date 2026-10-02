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

/// Represents the **lexical tokens** produced by a YAML tokenizer/parser.
///
/// These tokens correspond to structural elements defined by the YAML 1.2
/// specification. They are used by the Jetleaf YAML parser to construct
/// higher-level nodes (mappings, sequences, scalars, documents, aliases, etc.).
///
/// ### Overview
/// YAML is composed of mappings (objects), sequences (lists), scalars
/// (primitive values), and anchors/aliases. As the parser reads input text,
/// it emits tokens indicating which structural event is occurring.
///
/// ### Token Types
/// - **MAPPING_START / MAPPING_END**  
///   Mark the beginning and end of a YAML mapping (equivalent to JSON `{}`).
///
/// - **KEY / VALUE**  
///   Represent a key–value pair inside a mapping.  
///   `KEY` precedes the mapping key, `VALUE` precedes the mapped value.
///
/// - **SEQUENCE_START / SEQUENCE_END**  
///   Mark the beginning and end of a YAML sequence (equivalent to JSON `[]`).
///
/// - **SCALAR**  
///   Represents a scalar value such as a string, number, boolean,
///   null, block scalar (`|` or `>`), or any plain scalar.
///
/// - **ALIAS**  
///   Represents an alias node (`*anchorName`) referencing an anchored value.
///
/// - **DOCUMENT_START / DOCUMENT_END**  
///   Correspond to YAML document markers:  
///   `---` (start), `...` (end).  
///   These are optional but meaningful in multi-document streams.
///
/// - **END_DOCUMENT**  
///   Indicates that the parser has reached the logical end of input.  
///   This may occur after a `DOCUMENT_END` token or implicitly at EOF.
///
/// ### Usage
/// These tokens are consumed by higher-level readers that construct
/// full document trees or perform streaming parsing.
///
/// ### See also
/// - YAML 1.2 Specification  
/// - `YamlParser`  
/// - `YamlDeserializationContext`
enum YamlToken {
  /// Start of a YAML mapping (dictionary/object).
  MAPPING_START,

  /// End of a YAML mapping.
  MAPPING_END,

  /// Key inside a mapping.
  KEY,

  /// Value corresponding to a key in a mapping or an element in a sequence.
  VALUE,

  /// Start of a YAML sequence (array/list).
  SEQUENCE_START,

  /// End of a YAML sequence.
  SEQUENCE_END,

  /// A scalar (simple) value.
  SCALAR,

  /// An alias referencing an anchored value.
  ALIAS,

  /// Logical end of the YAML document or stream.
  END_DOCUMENT,

  /// Explicit YAML document start marker (`---`).
  DOCUMENT_START,

  /// Explicit YAML document end marker (`...`).
  DOCUMENT_END, ANCHOR,
}