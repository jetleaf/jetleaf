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

import 'dart:typed_data';

import 'package:jetleaf_core/lang.dart';

import 'io_request.dart';
import 'package:jetleaf_core/io.dart';

/// {@template io_form_request}
/// Represents an `application/x-www-form-urlencoded` HTTP request whose body
/// has been parsed into form parameters.
///
/// Parsing form bodies into the same parameter map as query-string parameters
/// lets `@RequestParam` binders work identically for `GET /?q=a` and
/// `POST /form` with `q=a` — the documented behavior of Jetleaf's
/// [RequestParamResolver](../../web/annotation/resolvers.dart).
///
/// The raw body bytes are retained so controllers that also want the raw
/// payload (e.g. for signature checks) can re-read it via [getBody].
///
/// **Example Usage:**
/// ```dart
/// final formRequest = IoFormRequest(request, {'name': ['Ada']}, bodyBytes);
/// formRequest.getParameter('name'); // 'Ada'
/// ```
/// {@endtemplate}
base class IoFormRequest extends IoRequest {
  /// Parsed form parameters keyed by field name.
  final Map<String, List<String>> _params;

  /// The raw body bytes, retained for [getBody] re-reads.
  final Uint8List _bodyBytes;

  /// Creates an [IoFormRequest] wrapping [source]'s underlying HTTP request,
  /// carrying the parsed [params] and the raw [bodyBytes].
  IoFormRequest(IoRequest source, this._params, this._bodyBytes)
      : super(source.getRequest(), source.getContextPath());

  @override
  String? getParameter(String name) {
    final formValues = _params[name];
    if (formValues?.isNotEmpty == true) {
      return formValues!.first;
    }

    return super.getParameter(name);
  }

  @override
  List<String> getParameterValues(String name) {
    final merged = <String>[
      ...super.getParameterValues(name),
      ...?_params[name],
    ];
    return List.unmodifiable(merged);
  }

  @override
  Map<String, List<String>> getParameterMap() {
    final merged = <String, List<String>>{
      ...super.getParameterMap(),
    };

    for (final entry in _params.entries) {
      merged.update(entry.key, (values) => [...values, ...entry.value], ifAbsent: () => List.of(entry.value));
    }

    return Map.unmodifiable(merged);
  }

  @override
  InputStream getBody() => ByteArrayInputStream(_bodyBytes);
}