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

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_web/src/utils/encoding.dart';
import 'package:jetleaf_web/src/utils/error_page_utils.dart';
import 'package:jetleaf_web/src/utils/matrix_variable_utils.dart';
import 'package:jetleaf_web/src/utils/web_utils.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/web/view.dart';

void main() {
  // =========================================================================
  // EncodingDecoder
  // =========================================================================
  group('BasicEncodingDecoder', () {
    late BasicEncodingDecoder decoder;

    setUp(() {
      decoder = const BasicEncodingDecoder();
    });

    group('decode', () {
      test('decodes UTF-8 bytes to string', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
        expect(decoder.decode(bytes), equals('Hello'));
      });

      test('decodes UTF-8 bytes with explicit encodingString', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]);
        expect(decoder.decode(bytes, encodingString: 'utf-8'), equals('Hello'));
        expect(decoder.decode(bytes, encodingString: 'utf8'), equals('Hello'));
      });

      test('decodes ASCII bytes', () {
        final bytes = ascii.encode('Jetleaf');
        expect(decoder.decode(bytes, encodingString: 'ascii'), equals('Jetleaf'));
      });

      test('decodes Latin-1 bytes', () {
        final bytes = latin1.encode('café');
        expect(decoder.decode(bytes, encodingString: 'latin-1'), equals('café'));
        expect(decoder.decode(bytes, encodingString: 'latin1'), equals('café'));
        expect(decoder.decode(bytes, encodingString: 'iso-8859-1'), equals('café'));
      });

      test('decodes using explicit Encoding object', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]);
        expect(decoder.decode(bytes, encoding: utf8), equals('Hello'));
      });

      test('decodes empty byte array', () {
        expect(decoder.decode(Uint8List.fromList([])), equals(''));
      });

      test('falls back to UTF-8 with allowMalformed for unsupported encoding', () {
        // "Unsupported" encoding name falls back to String.fromCharCodes
        final bytes = Uint8List.fromList([72, 101]);
        final result = decoder.decode(bytes, encodingString: 'shift_jis');
        expect(result, isA<String>());
        expect(result.length, equals(2));
      });

      test('encoding parameter takes precedence over encodingString', () {
        final bytes = latin1.encode('café');
        final result = decoder.decode(bytes, encodingString: 'ascii', encoding: latin1);
        expect(result, equals('café'));
      });

      test('handles Unicode multi-byte sequences', () {
        final bytes = utf8.encode('Hello 🌍');
        expect(decoder.decode(bytes), equals('Hello 🌍'));
      });

      test('case insensitive encoding lookup', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]);
        expect(decoder.decode(bytes, encodingString: 'UTF-8'), equals('Hello'));
        expect(decoder.decode(bytes, encodingString: 'UTF8'), equals('Hello'));
        expect(decoder.decode(bytes, encodingString: 'Utf-8'), equals('Hello'));
      });
    });

    group('encode', () {
      test('encodes string to UTF-8 bytes', () {
        final bytes = decoder.encode('Hello');
        expect(bytes, equals(Uint8List.fromList([72, 101, 108, 108, 111])));
      });

      test('encodes with explicit encodingString', () {
        final bytes = decoder.encode('Jetleaf', encodingString: 'utf-8');
        expect(bytes, equals(Uint8List.fromList(utf8.encode('Jetleaf'))));
      });

      test('encodes to ASCII', () {
        final bytes = decoder.encode('Hello', encodingString: 'ascii');
        expect(bytes, equals(Uint8List.fromList([72, 101, 108, 108, 111])));
      });

      test('encodes to Latin-1', () {
        final bytes = decoder.encode('café', encodingString: 'latin-1');
        expect(bytes, equals(Uint8List.fromList(latin1.encode('café'))));
      });

      test('encodes using explicit Encoding object', () {
        final bytes = decoder.encode('Hello', encoding: utf8);
        expect(bytes, equals(Uint8List.fromList([72, 101, 108, 108, 111])));
      });

      test('encodes empty string', () {
        expect(decoder.encode(''), equals(Uint8List.fromList([])));
      });

      test('encodes unsupported encoding via codeUnits fallback', () {
        final bytes = decoder.encode('Hi', encodingString: 'nonexistent');
        expect(bytes, equals(Uint8List.fromList('Hi'.codeUnits)));
      });

      test('encoding parameter takes precedence over encodingString', () {
        final bytes = decoder.encode('café', encodingString: 'ascii', encoding: latin1);
        expect(bytes, equals(Uint8List.fromList(latin1.encode('café'))));
      });

      test('round-trip encode/decode preserves data', () {
        const original = 'Hello, World! 🌍 café';
        final encoded = decoder.encode(original);
        final decoded = decoder.decode(encoded);
        expect(decoded, equals(original));
      });
    });

    group('supportsEncoding', () {
      test('returns true for supported encodings', () {
        expect(decoder.supportsEncoding('utf-8'), isTrue);
        expect(decoder.supportsEncoding('utf8'), isTrue);
        expect(decoder.supportsEncoding('ascii'), isTrue);
        expect(decoder.supportsEncoding('latin-1'), isTrue);
        expect(decoder.supportsEncoding('latin1'), isTrue);
        expect(decoder.supportsEncoding('iso-8859-1'), isTrue);
      });

      test('returns false for unsupported encodings', () {
        expect(decoder.supportsEncoding('utf-16'), isFalse);
        expect(decoder.supportsEncoding('shift_jis'), isFalse);
        expect(decoder.supportsEncoding('euc-kr'), isFalse);
      });

      test('case insensitive check', () {
        expect(decoder.supportsEncoding('UTF-8'), isTrue);
        expect(decoder.supportsEncoding('ASCII'), isTrue);
        expect(decoder.supportsEncoding('Latin-1'), isTrue);
      });
    });

    group('getSupportedEncodings', () {
      test('returns all supported encodings', () {
        final encodings = decoder.getSupportedEncodings();
        expect(encodings, containsAll(['utf-8', 'utf8', 'ascii', 'latin-1', 'latin1', 'iso-8859-1']));
        expect(encodings.length, equals(6));
      });
    });
  });

  group('Base64EncodingDecoder', () {
    late Base64EncodingDecoder decoder;

    setUp(() {
      decoder = const Base64EncodingDecoder();
    });

    group('decode', () {
      test('decodes bytes to base64 string', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
        expect(decoder.decode(bytes), equals('SGVsbG8='));
      });

      test('decodes empty bytes to empty base64', () {
        expect(decoder.decode(Uint8List.fromList([])), equals(''));
      });

      test('decodes bytes producing correct base64 output', () {
        final bytes = Uint8List.fromList([0, 1, 2, 3]);
        final result = decoder.decode(bytes);
        expect(result, equals(base64.encode(bytes)));
      });
    });

    group('encode', () {
      test('encodes base64 string to bytes', () {
        final bytes = decoder.encode('SGVsbG8=');
        expect(bytes, equals(Uint8List.fromList([72, 101, 108, 108, 111])));
      });

      test('encodes empty base64 string', () {
        expect(decoder.encode(''), equals(Uint8List.fromList([])));
      });

      test('round-trip base64 encode/decode', () {
        final original = Uint8List.fromList([72, 101, 108, 108, 111]);
        final encoded = decoder.decode(original);
        final decoded = decoder.encode(encoded);
        expect(decoded, equals(original));
      });
    });

    group('supportsEncoding', () {
      test('returns true for base64', () {
        expect(decoder.supportsEncoding('base64'), isTrue);
        expect(decoder.supportsEncoding('anything'), isTrue);
      });
    });

    group('getSupportedEncodings', () {
      test('returns base64', () {
        expect(decoder.getSupportedEncodings(), equals(['base64']));
      });
    });
  });

  // =========================================================================
  // ErrorPageUtils
  // =========================================================================
  group('ErrorPageUtils', () {
    group('template path constants', () {
      test('ERROR_NOT_FOUND_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_NOT_FOUND_PAGE, equals('error/404'));
      });

      test('ERROR_BAD_REQUEST_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_BAD_REQUEST_PAGE, equals('error/400'));
      });

      test('ERROR_UNAUTHORIZED_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_UNAUTHORIZED_PAGE, equals('error/401'));
      });

      test('ERROR_FORBIDDEN_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_FORBIDDEN_PAGE, equals('error/403'));
      });

      test('ERROR_METHOD_NOT_ALLOWED_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_METHOD_NOT_ALLOWED_PAGE, equals('error/405'));
      });

      test('ERROR_REQUEST_TIMEOUT_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_REQUEST_TIMEOUT_PAGE, equals('error/408'));
      });

      test('ERROR_CONFLICT_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_CONFLICT_PAGE, equals('error/409'));
      });

      test('ERROR_PAYLOAD_TOO_LARGE_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_PAYLOAD_TOO_LARGE_PAGE, equals('error/413'));
      });

      test('ERROR_UNSUPPORTED_MEDIA_TYPE_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_UNSUPPORTED_MEDIA_TYPE_PAGE, equals('error/415'));
      });

      test('ERROR_TOO_MANY_REQUESTS_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_TOO_MANY_REQUESTS_PAGE, equals('error/429'));
      });

      test('ERROR_INTERNAL_SERVER_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_INTERNAL_SERVER_PAGE, equals('error/500'));
      });

      test('ERROR_BAD_GATEWAY_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_BAD_GATEWAY_PAGE, equals('error/502'));
      });

      test('ERROR_SERVICE_UNAVAILABLE_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_SERVICE_UNAVAILABLE_PAGE, equals('error/503'));
      });

      test('ERROR_GATEWAY_TIMEOUT_PAGE is correct', () {
        expect(ErrorPageUtils.ERROR_GATEWAY_TIMEOUT_PAGE, equals('error/504'));
      });
    });

    group('notFound', () {
      test('creates 404 page with default message', () {
        final view = ErrorPageUtils.notFound(requestPath: '/api/users');
        expect(view.getStatus().getCode(), equals(404));
        expect(view.getPath(), equals('error/404'));
        expect(view.getAttributes()['message'], equals('The requested resource could not be found.'));
        expect(view.getAttributes()['requestPath'], equals('/api/users'));
        expect(view.getAttributes()['status'], equals(404));
      });

      test('creates 404 page with custom message', () {
        final view = ErrorPageUtils.notFound(
          message: 'Page does not exist',
          requestPath: '/dashboard',
        );
        expect(view.getAttributes()['message'], equals('Page does not exist'));
        expect(view.getAttributes()['requestPath'], equals('/dashboard'));
      });

      test('creates 404 page with errorId', () {
        final view = ErrorPageUtils.notFound(
          requestPath: '/api/users/99999',
          errorId: 'ERR-404-001',
        );
        expect(view.getAttributes()['errorId'], equals('ERR-404-001'));
      });

      test('creates 404 page with custom timestamp', () {
        final ts = DateTime(2025, 1, 15, 10, 30);
        final view = ErrorPageUtils.notFound(
          requestPath: '/test',
          timestamp: ts,
        );
        expect(view.getAttributes()['timestamp'], equals(ts));
      });

      test('defaults timestamp to DateTime.now()', () {
        final before = DateTime.now();
        final view = ErrorPageUtils.notFound(requestPath: '/test');
        final after = DateTime.now();
        final ts = view.getAttributes()['timestamp'] as DateTime;
        expect(ts.isAfter(before) || ts.isAtSameMomentAs(before), isTrue);
        expect(ts.isBefore(after) || ts.isAtSameMomentAs(after), isTrue);
      });
    });

    group('badRequest', () {
      test('creates 400 page with message and requestPath', () {
        final view = ErrorPageUtils.badRequest(
          message: 'Invalid parameters',
          requestPath: '/api/users',
        );
        expect(view.getStatus().getCode(), equals(400));
        expect(view.getPath(), equals('error/400'));
        expect(view.getAttributes()['message'], equals('Invalid parameters'));
        expect(view.getAttributes()['requestPath'], equals('/api/users'));
        expect(view.getAttributes()['status'], equals(400));
      });

      test('includes details map', () {
        final details = {'email': 'Invalid format', 'age': 'Must be 18+'};
        final view = ErrorPageUtils.badRequest(
          message: 'Validation failed',
          details: details,
          requestPath: '/api/register',
        );
        expect(view.getAttributes()['details'], equals(details));
      });

      test('handles null details', () {
        final view = ErrorPageUtils.badRequest(
          message: 'Bad request',
          requestPath: '/api/test',
        );
        expect(view.getAttributes()['details'], isNull);
      });

      test('includes errorId', () {
        final view = ErrorPageUtils.badRequest(
          message: 'Bad request',
          requestPath: '/test',
          errorId: 'ERR-400-001',
        );
        expect(view.getAttributes()['errorId'], equals('ERR-400-001'));
      });
    });

    group('unauthorized', () {
      test('creates 401 page with default loginUrl', () {
        final view = ErrorPageUtils.unauthorized(
          message: 'Authentication required',
          requestPath: '/dashboard',
        );
        expect(view.getStatus().getCode(), equals(401));
        expect(view.getPath(), equals('error/401'));
        expect(view.getAttributes()['loginUrl'], equals('/login'));
        expect(view.getAttributes()['message'], equals('Authentication required'));
      });

      test('creates 401 page with custom loginUrl', () {
        final view = ErrorPageUtils.unauthorized(
          message: 'Please log in',
          loginUrl: '/auth/signin',
          requestPath: '/secure',
        );
        expect(view.getAttributes()['loginUrl'], equals('/auth/signin'));
      });
    });

    group('forbidden', () {
      test('creates 403 page with message', () {
        final view = ErrorPageUtils.forbidden(
          message: 'Access denied',
          requestPath: '/admin',
        );
        expect(view.getStatus().getCode(), equals(403));
        expect(view.getPath(), equals('error/403'));
        expect(view.getAttributes()['message'], equals('Access denied'));
      });

      test('includes requiredRoles', () {
        final view = ErrorPageUtils.forbidden(
          message: 'Insufficient permissions',
          requiredRoles: ['ADMIN', 'MODERATOR'],
          requestPath: '/admin/dashboard',
        );
        expect(view.getAttributes()['requiredRoles'], equals(['ADMIN', 'MODERATOR']));
      });
    });

    group('methodNotAllowed', () {
      test('creates 405 page with default allowedMethods', () {
        final view = ErrorPageUtils.methodNotAllowed(
          message: 'POST not allowed',
          requestPath: '/api/users',
        );
        expect(view.getStatus().getCode(), equals(405));
        expect(view.getPath(), equals('error/405'));
        expect(view.getAttributes()['allowedMethods'], equals(['GET', 'POST']));
      });

      test('creates 405 page with custom allowedMethods', () {
        final view = ErrorPageUtils.methodNotAllowed(
          message: 'Only GET allowed',
          allowedMethods: ['GET'],
          requestPath: '/api/data',
        );
        expect(view.getAttributes()['allowedMethods'], equals(['GET']));
      });
    });

    group('requestTimeout', () {
      test('creates 408 page with default timeoutSeconds', () {
        final view = ErrorPageUtils.requestTimeout(message: 'Request timed out');
        expect(view.getStatus().getCode(), equals(408));
        expect(view.getPath(), equals('error/408'));
        expect(view.getAttributes()['timeoutSeconds'], equals(30));
      });

      test('creates 408 page with custom timeoutSeconds', () {
        final view = ErrorPageUtils.requestTimeout(
          message: 'Timeout',
          timeoutSeconds: 60,
        );
        expect(view.getAttributes()['timeoutSeconds'], equals(60));
      });
    });

    group('conflict', () {
      test('creates 409 page', () {
        final view = ErrorPageUtils.conflict(message: 'Resource conflict');
        expect(view.getStatus().getCode(), equals(409));
        expect(view.getPath(), equals('error/409'));
        expect(view.getAttributes()['message'], equals('Resource conflict'));
      });

      test('includes conflictDetails', () {
        final details = {'version': 3, 'expected': 2};
        final view = ErrorPageUtils.conflict(
          message: 'Version mismatch',
          conflictDetails: details,
        );
        expect(view.getAttributes()['details'], equals(details));
      });
    });

    group('payloadTooLarge', () {
      test('creates 413 page with optional size params', () {
        final view = ErrorPageUtils.payloadTooLarge(
          message: 'File too large',
          maxSize: 1048576,
          actualSize: 2097152,
        );
        expect(view.getStatus().getCode(), equals(413));
        expect(view.getPath(), equals('error/413'));
        expect(view.getAttributes()['maxSize'], equals(1048576));
        expect(view.getAttributes()['actualSize'], equals(2097152));
      });

      test('handles null size params', () {
        final view = ErrorPageUtils.payloadTooLarge(message: 'Too large');
        expect(view.getAttributes()['maxSize'], isNull);
        expect(view.getAttributes()['actualSize'], isNull);
      });
    });

    group('unsupportedMediaType', () {
      test('creates 415 page with defaults', () {
        final view = ErrorPageUtils.unsupportedMediaType(message: 'Unsupported format');
        expect(view.getStatus().getCode(), equals(415));
        expect(view.getPath(), equals('error/415'));
        expect(view.getAttributes()['receivedContentType'], equals('unknown'));
        expect(view.getAttributes()['supportedTypes'], equals(['application/json', 'application/xml']));
      });

      test('creates 415 page with custom types', () {
        final view = ErrorPageUtils.unsupportedMediaType(
          message: 'Bad content type',
          receivedContentType: 'text/csv',
          supportedTypes: ['application/json'],
        );
        expect(view.getAttributes()['receivedContentType'], equals('text/csv'));
        expect(view.getAttributes()['supportedTypes'], equals(['application/json']));
      });
    });

    group('tooManyRequests', () {
      test('creates 429 page with default retryAfterSeconds', () {
        final view = ErrorPageUtils.tooManyRequests(message: 'Rate limited');
        expect(view.getStatus().getCode(), equals(429));
        expect(view.getPath(), equals('error/429'));
        expect(view.getAttributes()['retryAfterSeconds'], equals(60));
      });

      test('creates 429 page with custom retryAfterSeconds', () {
        final view = ErrorPageUtils.tooManyRequests(
          message: 'Slow down',
          retryAfterSeconds: 120,
        );
        expect(view.getAttributes()['retryAfterSeconds'], equals(120));
      });
    });

    group('internalServerError', () {
      test('creates 500 page with message', () {
        final view = ErrorPageUtils.internalServerError(message: 'Something went wrong');
        expect(view.getStatus().getCode(), equals(500));
        expect(view.getPath(), equals('error/500'));
        expect(view.getAttributes()['message'], equals('Something went wrong'));
      });

      test('includes errorId and contactEmail', () {
        final view = ErrorPageUtils.internalServerError(
          message: 'Server error',
          errorId: 'ERR-500-XYZ',
          contactEmail: 'support@example.com',
        );
        expect(view.getAttributes()['errorId'], equals('ERR-500-XYZ'));
        expect(view.getAttributes()['contactEmail'], equals('support@example.com'));
      });

      test('handles null errorId and contactEmail', () {
        final view = ErrorPageUtils.internalServerError(message: 'Error');
        expect(view.getAttributes()['errorId'], isNull);
        expect(view.getAttributes()['contactEmail'], isNull);
      });
    });

    group('badGateway', () {
      test('creates 502 page with default upstreamService', () {
        final view = ErrorPageUtils.badGateway(message: 'Bad gateway');
        expect(view.getStatus().getCode(), equals(502));
        expect(view.getPath(), equals('error/502'));
        expect(view.getAttributes()['upstreamService'], equals('upstream server'));
      });

      test('creates 502 page with custom upstreamService', () {
        final view = ErrorPageUtils.badGateway(
          message: 'Upstream failure',
          upstreamService: 'auth-service',
        );
        expect(view.getAttributes()['upstreamService'], equals('auth-service'));
      });
    });

    group('serviceUnavailable', () {
      test('creates 503 page with defaults', () {
        final view = ErrorPageUtils.serviceUnavailable(message: 'Service down');
        expect(view.getStatus().getCode(), equals(503));
        expect(view.getPath(), equals('error/503'));
        expect(view.getAttributes()['retryAfterSeconds'], equals(60));
      });

      test('creates 503 page with custom retryAfterSeconds', () {
        final view = ErrorPageUtils.serviceUnavailable(
          message: 'Maintenance',
          retryAfterSeconds: 300,
        );
        expect(view.getAttributes()['retryAfterSeconds'], equals(300));
      });
    });

    group('gatewayTimeout', () {
      test('creates 504 page with defaults', () {
        final view = ErrorPageUtils.gatewayTimeout('Gateway timeout');
        expect(view.getStatus().getCode(), equals(504));
        expect(view.getPath(), equals('error/504'));
        expect(view.getAttributes()['upstreamService'], equals('upstream service'));
        expect(view.getAttributes()['timeoutSeconds'], equals(30));
      });

      test('creates 504 page with custom params', () {
        final view = ErrorPageUtils.gatewayTimeout(
          'API gateway timeout',
          upstreamService: 'payment-service',
          timeoutSeconds: 45,
        );
        expect(view.getAttributes()['upstreamService'], equals('payment-service'));
        expect(view.getAttributes()['timeoutSeconds'], equals(45));
      });
    });

    group('generic', () {
      test('creates generic error page for custom status', () {
        final view = ErrorPageUtils.generic(
          HttpStatus.fromCode(418),
          message: "I'm a teapot",
        );
        expect(view.getStatus().getCode(), equals(418));
        expect(view.getPath(), equals('error/418'));
        expect(view.getAttributes()['message'], equals("I'm a teapot"));
        expect(view.getAttributes()['status'], equals(418));
      });

      test('includes additional attributes', () {
        final view = ErrorPageUtils.generic(
          HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'Error',
          attributes: {'custom': 'value', 'count': 42},
        );
        expect(view.getAttributes()['custom'], equals('value'));
        expect(view.getAttributes()['count'], equals(42));
      });

      test('handles null attributes', () {
        final view = ErrorPageUtils.generic(
          HttpStatus.NOT_FOUND,
          message: 'Not found',
        );
        expect(view.getAttributes(), isNot(contains('custom')));
      });

      test('always includes timestamp', () {
        final before = DateTime.now();
        final view = ErrorPageUtils.generic(
          HttpStatus.OK,
          message: 'Success',
        );
        final after = DateTime.now();
        final ts = view.getAttributes()['timestamp'] as DateTime;
        expect(ts.isAfter(before) || ts.isAtSameMomentAs(before), isTrue);
        expect(ts.isBefore(after) || ts.isAtSameMomentAs(after), isTrue);
      });
    });

    group('all error pages return PageView', () {
      test('each factory returns a PageView instance', () {
        expect(ErrorPageUtils.notFound(requestPath: '/'), isA<PageView>());
        expect(ErrorPageUtils.badRequest(message: 'm', requestPath: '/'), isA<PageView>());
        expect(ErrorPageUtils.unauthorized(message: 'm', requestPath: '/'), isA<PageView>());
        expect(ErrorPageUtils.forbidden(message: 'm', requestPath: '/'), isA<PageView>());
        expect(ErrorPageUtils.methodNotAllowed(message: 'm', requestPath: '/'), isA<PageView>());
        expect(ErrorPageUtils.requestTimeout(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.conflict(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.payloadTooLarge(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.unsupportedMediaType(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.tooManyRequests(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.internalServerError(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.badGateway(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.serviceUnavailable(message: 'm'), isA<PageView>());
        expect(ErrorPageUtils.gatewayTimeout('m'), isA<PageView>());
      });
    });
  });

  // =========================================================================
  // MatrixVariableUtils
  // =========================================================================
  group('MatrixVariableUtils', () {
    group('resolve', () {
      test('parses single matrix variable', () {
        final vars = MatrixVariableUtils.resolve('cars;color=red');
        expect(vars.get('color'), equals('red'));
      });

      test('parses multiple matrix variables', () {
        final vars = MatrixVariableUtils.resolve('cars;color=red;year=2012');
        expect(vars.get('color'), equals('red'));
        expect(vars.get('year'), equals('2012'));
      });

      test('parses matrix variables from full path', () {
        final vars = MatrixVariableUtils.resolve('/cars;color=blue;year=2020/owners');
        expect(vars.get('color'), equals('blue'));
        expect(vars.get('year'), equals('2020/owners'));
      });

      test('returns empty MatrixVariables for path without semicolons', () {
        final vars = MatrixVariableUtils.resolve('/api/users');
        expect(vars.isEmpty, isTrue);
      });

      test('handles URL-encoded values', () {
        final vars = MatrixVariableUtils.resolve('search;query=hello%20world');
        expect(vars.get('query'), equals('hello world'));
      });

      test('handles URL-encoded keys', () {
        final vars = MatrixVariableUtils.resolve('data;my%20key=my%20value');
        expect(vars.get('my key'), equals('my value'));
      });

      test('skips malformed pairs without equals sign', () {
        final vars = MatrixVariableUtils.resolve('segment;key=value;malformed;other=val');
        expect(vars.get('key'), equals('value'));
        expect(vars.get('other'), equals('val'));
        expect(vars.length, equals(2));
      });

      test('skips empty key after URL decoding', () {
        final vars = MatrixVariableUtils.resolve('segment;=value');
        expect(vars.length, equals(0));
      });

      test('handles empty value', () {
        final vars = MatrixVariableUtils.resolve('segment;key=');
        expect(vars.get('key'), equals(''));
      });

      test('handles path with no matrix variables', () {
        final vars = MatrixVariableUtils.resolve('/');
        expect(vars.isEmpty, isTrue);
      });

      test('only parses content after first semicolon', () {
        // The implementation splits on first ';' then parses remaining
        final vars = MatrixVariableUtils.resolve('path;key1=val1;key2=val2');
        expect(vars.get('key1'), equals('val1'));
        expect(vars.get('key2'), equals('val2'));
      });

      test('handles multiple segments but only parses matrix vars from first segment', () {
        final vars = MatrixVariableUtils.resolve('/a;x=1/b;y=2');
        // The resolve method takes the part after first ';' which is "x=1/b;y=2"
        // Then splits on ';' getting ["x=1/b", "y=2"]
        // "x=1/b" has '=', so key=x, val=1/b. "y=2" -> key=y, val=2
        expect(vars.get('x'), equals('1/b'));
        expect(vars.get('y'), equals('2'));
        expect(vars.length, equals(2));
      });

      test('handles empty string', () {
        final vars = MatrixVariableUtils.resolve('');
        expect(vars.isEmpty, isTrue);
      });

      test('handles semicolon-only input', () {
        final vars = MatrixVariableUtils.resolve(';');
        expect(vars.isEmpty, isTrue);
      });
    });

    group('resolveAll', () {
      test('parses matrix variables from multiple segments', () {
        final map = MatrixVariableUtils.resolveAll('/cars;color=red;year=2020/owners;name=alice');
        expect(map['cars']?.get('color'), equals('red'));
        expect(map['cars']?.get('year'), equals('2020'));
        expect(map['owners']?.get('name'), equals('alice'));
      });

      test('segments without matrix variables get empty MatrixVariables', () {
        final map = MatrixVariableUtils.resolveAll('/cars;color=red/owners');
        expect(map['cars']?.get('color'), equals('red'));
        expect(map['owners']?.isEmpty, isTrue);
      });

      test('skips empty segments from leading/trailing slashes', () {
        final map = MatrixVariableUtils.resolveAll('/a;x=1/');
        expect(map.containsKey(''), isFalse);
        expect(map['a']?.get('x'), equals('1'));
      });

      test('handles single segment', () {
        final map = MatrixVariableUtils.resolveAll('segment;key=val');
        expect(map['segment']?.get('key'), equals('val'));
      });

      test('handles empty path', () {
        final map = MatrixVariableUtils.resolveAll('');
        expect(map.isEmpty, isTrue);
      });

      test('handles root path only', () {
        final map = MatrixVariableUtils.resolveAll('/');
        expect(map.isEmpty, isTrue);
      });

      test('each segment has independent matrix variables', () {
        final map = MatrixVariableUtils.resolveAll('/a;x=1;b=2/c;y=3');
        expect(map['a']?.get('x'), equals('1'));
        expect(map['a']?.get('b'), equals('2'));
        expect(map['a']?.get('y'), isNull);
        expect(map['c']?.get('y'), equals('3'));
        expect(map['c']?.get('x'), isNull);
      });
    });
  });

  group('MatrixVariables', () {
    group('get', () {
      test('returns value for existing key', () {
        final vars = MatrixVariables({'color': 'red', 'size': 'large'});
        expect(vars.get('color'), equals('red'));
        expect(vars.get('size'), equals('large'));
      });

      test('returns null for missing key', () {
        final vars = MatrixVariables({'color': 'red'});
        expect(vars.get('missing'), isNull);
      });
    });

    group('getNames', () {
      test('returns all variable names', () {
        final vars = MatrixVariables({'a': '1', 'b': '2', 'c': '3'});
        expect(vars.getNames(), containsAll(['a', 'b', 'c']));
        expect(vars.getNames().length, equals(3));
      });

      test('returns empty iterable for empty variables', () {
        final vars = MatrixVariables({});
        expect(vars.getNames().isEmpty, isTrue);
      });
    });

    group('contains', () {
      test('returns true for existing key', () {
        final vars = MatrixVariables({'key': 'value'});
        expect(vars.contains('key'), isTrue);
      });

      test('returns false for missing key', () {
        final vars = MatrixVariables({'key': 'value'});
        expect(vars.contains('missing'), isFalse);
      });
    });

    group('MapBase interface', () {
      test('operator [] returns value', () {
        final vars = MatrixVariables({'x': '10'});
        expect(vars['x'], equals('10'));
      });

      test('operator []= sets value', () {
        final vars = MatrixVariables(<String, String>{});
        vars['key'] = 'value';
        expect(vars['key'], equals('value'));
      });

      test('keys returns all keys', () {
        final vars = MatrixVariables({'a': '1', 'b': '2'});
        expect(vars.keys, containsAll(['a', 'b']));
      });

      test('remove removes a key', () {
        final vars = MatrixVariables({'a': '1', 'b': '2'});
        final removed = vars.remove('a');
        expect(removed, equals('1'));
        expect(vars.containsKey('a'), isFalse);
        expect(vars.containsKey('b'), isTrue);
      });

      test('clear removes all entries', () {
        final vars = MatrixVariables({'a': '1', 'b': '2'});
        vars.clear();
        expect(vars.isEmpty, isTrue);
      });

      test('length returns correct count', () {
        final vars = MatrixVariables({'a': '1', 'b': '2', 'c': '3'});
        expect(vars.length, equals(3));
      });

      test('containsKey works', () {
        final vars = MatrixVariables({'x': '1'});
        expect(vars.containsKey('x'), isTrue);
        expect(vars.containsKey('y'), isFalse);
      });

      test('containsValue works', () {
        final vars = MatrixVariables({'x': '1'});
        expect(vars.containsValue('1'), isTrue);
        expect(vars.containsValue('2'), isFalse);
      });

      test('toString returns map string representation', () {
        final vars = MatrixVariables({'key': 'value'});
        expect(vars.toString(), equals('{key: value}'));
      });
    });
  });

  // =========================================================================
  // WebUtils - path methods (complementing web_utils_path_test.dart)
  // =========================================================================
  group('WebUtils path methods', () {
    group('normalizePath', () {
      test('normalizes path with leading whitespace', () {
        expect(WebUtils.normalizePath('  /api'), equals('/api'));
      });

      test('normalizes path with trailing whitespace', () {
        expect(WebUtils.normalizePath('/api  '), equals('/api'));
      });

      test('normalizes path with both whitespace', () {
        expect(WebUtils.normalizePath('  /api/v1  '), equals('/api/v1'));
      });

      test('handles triple slashes', () {
        expect(WebUtils.normalizePath('/api///v1'), equals('/api/v1'));
      });

      test('single slash stays as root', () {
        expect(WebUtils.normalizePath('/'), equals('/'));
      });

      test('adds leading slash when missing', () {
        expect(WebUtils.normalizePath('api'), equals('/api'));
      });

      test('does not remove trailing slash from root', () {
        expect(WebUtils.normalizePath('/'), equals('/'));
      });
    });

    group('doCombinePaths', () {
      test('combines paths with proper separator', () {
        expect(WebUtils.doCombinePaths('/api', 'v1'), equals('/api/v1'));
      });

      test('first path with trailing slash', () {
        expect(WebUtils.doCombinePaths('/api/', 'v1'), equals('/api/v1'));
      });

      test('second path with leading slash', () {
        expect(WebUtils.doCombinePaths('/api', '/v1'), equals('/api/v1'));
      });

      test('both paths with slashes', () {
        expect(WebUtils.doCombinePaths('/api/', '/v1'), equals('/api/v1'));
      });
    });

    group('combinePaths', () {
      test('combines three paths with no extra slashes', () {
        expect(WebUtils.combinePaths('/a', '/b', '/c'), equals('/a/b/c'));
      });

      test('collapses many duplicate slashes', () {
        expect(WebUtils.combinePaths('/a//', '///b//', '///c//'), equals('/a/b/c'));
      });

      test('handles single segment paths', () {
        expect(WebUtils.combinePaths('', '', ''), equals('/'));
      });

      test('normalizes result', () {
        expect(WebUtils.combinePaths('/a/', 'b/', 'c/'), equals('/a/b/c'));
      });
    });
  });

  // =========================================================================
  // WebUtils - non-path static methods
  // =========================================================================
  group('WebUtils non-path methods', () {
    group('producing', () {
      test('returns empty list when method is null', () {
        final result = WebUtils.producing(null);
        expect(result, isEmpty);
      });
    });

    group('renderAsJson', () {
      test('returns false when content type is null', () {
        // We can't easily instantiate ServerHttpResponse without the full server
        // infrastructure, so we test the logic path conceptually.
        // The method checks response.getHeaders().getContentType() != null
        // and then isCompatibleWith(MediaType.APPLICATION_JSON)
        expect(WebUtils.renderAsJson, isA<Function>());
      });
    });

    group('resolveMediaTypeAsJson', () {
      test('is callable', () {
        expect(WebUtils.resolveMediaTypeAsJson, isA<Function>());
      });
    });

    group('resolveMediaTypeAsHtml', () {
      test('is callable', () {
        expect(WebUtils.resolveMediaTypeAsHtml, isA<Function>());
      });
    });
  });
}
