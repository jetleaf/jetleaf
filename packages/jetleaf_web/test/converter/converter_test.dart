import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetson/jetson.dart';
import 'package:test/test.dart';
import 'package:jetleaf_web/src/converter/abstract_http_message_converter.dart';
import 'package:jetleaf_web/src/converter/common_http_message_converters.dart';
import 'package:jetleaf_web/src/converter/form_http_message_converter.dart';
import 'package:jetleaf_web/src/converter/http_message_converter_registry.dart';
import 'package:jetleaf_web/src/converter/http_message_converters.dart';
import 'package:jetleaf_web/src/converter/jetson_2_http_message_converter.dart';
import 'package:jetleaf_web/src/exception/exceptions.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_message.dart';
import 'package:jetleaf_web/src/http/media_type.dart';

// ---------------------------------------------------------------------------
// Test helpers: minimal HttpInputMessage / HttpOutputMessage implementations
// ---------------------------------------------------------------------------

class _TestInputMessage implements HttpInputMessage {
  HttpHeaders _headers;
  final InputStream _body;

  _TestInputMessage(this._body, [HttpHeaders? headers])
      : _headers = headers ?? HttpHeaders();

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {
    _headers = headers;
  }

  @override
  InputStream getBody() => _body;
}

class _TestOutputMessage implements HttpOutputMessage {
  HttpHeaders _headers;
  final OutputStream _body;

  _TestOutputMessage(this._body, [HttpHeaders? headers])
      : _headers = headers ?? HttpHeaders();

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {
    _headers = headers;
  }

  @override
  OutputStream getBody() => _body;
}

/// Creates an [InputStream] from a UTF-8 encoded string.
InputStream _inputStreamFromString(String data) {
  return ByteArrayInputStream(Uint8List.fromList(utf8.encode(data)));
}

/// Creates an [OutputStream] and returns it along with a reader that
/// collects everything written.
(OutputStream output, String Function() readWritten) _collectingOutputStream() {
  final buffer = ByteArrayOutputStream();
  return (buffer, () => utf8.decode(buffer.toByteArray()));
}

// ---------------------------------------------------------------------------
// A minimal concrete converter used purely for interface / registry tests.
// ---------------------------------------------------------------------------

class _StubConverter extends AbstractHttpMessageConverter<String> {
  bool readCalled = false;
  bool writeCalled = false;

  _StubConverter() {
    super.addSupportedMediaType(MediaType('application', 'x-stub'));
  }

  @override
  bool matchesType(Class type) => type.getType() == String;

  @override
  Future<String> readInternal(Class<String> type, HttpInputMessage inputMessage) async {
    readCalled = true;
    return inputMessage.getBody().readAsString();
  }

  @override
  Future<void> writeInternal(String object, HttpOutputMessage outputMessage) async {
    writeCalled = true;
    await outputMessage.getBody().writeString(object);
  }

  @override
  List<Object?> equalizedProperties() => [_StubConverter];
}

// ===================================================================
// Tests
// ===================================================================

@JetleafTest()
void main() {
  // ------------------------------------------------------------------
  // HttpMessageConverter interface contract
  // ------------------------------------------------------------------
  group('HttpMessageConverter interface', () {
    late _StubConverter converter;

    setUp(() {
      converter = _StubConverter();
    });

    test('getSupportedMediaTypes returns configured types', () {
      final types = converter.getSupportedMediaTypes();
      expect(types, hasLength(1));
      expect(types.first.getMimeType(), 'application/x-stub');
    });

    test('getClassSupportedMediaTypes delegates to getSupportedMediaTypes by default', () {
      final byClass = converter.getClassSupportedMediaTypes(Class<String>());
      final byDefault = converter.getSupportedMediaTypes();
      expect(byClass, equals(byDefault));
    });

    test('canRead returns true when media type is compatible', () {
      expect(converter.canRead(Class<String>(), MediaType('application', 'x-stub')), isTrue);
    });

    test('canRead returns true when matchesType matches regardless of media type', () {
      expect(converter.canRead(Class<String>()), isTrue);
      expect(converter.canRead(Class<String>(), MediaType('text', 'plain')), isTrue);
    });

    test('canRead returns false for incompatible media type', () {
      expect(converter.canRead(Class<int>(), MediaType('text', 'plain')), isFalse);
    });

    test('canWrite returns true when media type is compatible', () {
      expect(converter.canWrite(Class<String>(), MediaType('application', 'x-stub')), isTrue);
    });

    test('canWrite returns true when no media type is provided', () {
      expect(converter.canWrite(Class<String>()), isTrue);
    });

    test('canWrite returns false for incompatible media type', () {
      expect(converter.canWrite(Class<int>(), MediaType('text', 'plain')), isFalse);
    });

    test('read delegates to readInternal', () async {
      final input = _TestInputMessage(_inputStreamFromString('hello'));
      final result = await converter.read(Class<String>(), input);
      expect(result, 'hello');
      expect(converter.readCalled, isTrue);
    });

    test('write delegates to writeInternal', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write('world', null, msg);
      expect(converter.writeCalled, isTrue);
      expect(readFn(), 'world');
    });

    test('write sets default content-type from supported media types when contentType is null',
        () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write('test', null, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'application/x-stub');
    });

    test('write respects provided contentType', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      final custom = MediaType('text', 'plain');
      await converter.write('test', custom, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'text/plain');
    });
  });

  // ------------------------------------------------------------------
  // AbstractHttpMessageConverter – error wrapping
  // ------------------------------------------------------------------
  group('AbstractHttpMessageConverter error wrapping', () {
    test('read wraps exceptions in HttpMessageNotReadableException', () async {
      final converter = _FailingReadConverter();
      final input = _TestInputMessage(_inputStreamFromString('bad'));
      expect(
        () => converter.read(Class<String>(), input),
        throwsA(isA<HttpMessageNotReadableException>()),
      );
    });

    test('write wraps exceptions in HttpMessageNotWritableException', () async {
      final converter = _FailingWriteConverter();
      final output = ByteArrayOutputStream();
      final msg = _TestOutputMessage(output);
      expect(
        () => converter.write('bad', null, msg),
        throwsA(isA<HttpMessageNotWritableException>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // StringHttpMessageConverter
  // ------------------------------------------------------------------
  group('StringHttpMessageConverter', () {
    late StringHttpMessageConverter converter;

    setUp(() {
      converter = StringHttpMessageConverter();
    });

    test('supports text/plain media type', () {
      final types = converter.getSupportedMediaTypes();
      expect(types, contains(MediaType.TEXT_PLAIN));
    });

    test('matchesType returns true for String class', () {
      expect(converter.matchesType(Class<String>()), isTrue);
    });

    test('matchesType returns false for non-String class', () {
      expect(converter.matchesType(Class<int>()), isFalse);
    });

    test('canRead returns true for String type with text/plain', () {
      expect(converter.canRead(Class<String>(), MediaType.TEXT_PLAIN), isTrue);
    });

    test('canRead returns true for String type with no media type (via matchesType)', () {
      expect(converter.canRead(Class<String>()), isTrue);
    });

    test('canRead returns false for incompatible media type and type', () {
      expect(converter.canRead(Class<int>()), isFalse);
    });

    test('read returns the body as a string', () async {
      final input = _TestInputMessage(_inputStreamFromString('Hello Jetleaf'));
      final result = await converter.read(Class<String>(), input);
      expect(result, 'Hello Jetleaf');
    });

    test('write writes string to output', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write('Goodbye', null, msg);
      expect(readFn(), 'Goodbye');
    });

    test('write sets Content-Type header to text/plain', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write('x', null, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'text/plain');
    });
  });

  // ------------------------------------------------------------------
  // ByteArrayHttpMessageConverter
  // ------------------------------------------------------------------
  group('ByteArrayHttpMessageConverter', () {
    late ByteArrayHttpMessageConverter converter;

    setUp(() {
      converter = ByteArrayHttpMessageConverter();
    });

    test('supports application/octet-stream', () {
      final types = converter.getSupportedMediaTypes();
      expect(types, contains(MediaType.APPLICATION_OCTET_STREAM));
    });

    test('matchesType returns true for List<int>', () {
      expect(converter.matchesType(Class<List<int>>()), isTrue);
    });

    test('canRead returns true for List<int> type with matching media type', () {
      expect(
        converter.canRead(Class<List<int>>(), MediaType.APPLICATION_OCTET_STREAM),
        isTrue,
      );
    });

    test('canRead returns true for List<int> type with null media type (via matchesType)', () {
      expect(converter.canRead(Class<List<int>>()), isTrue);
    });

    test('read returns raw bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final input = _TestInputMessage(ByteArrayInputStream(bytes));
      final result = await converter.read(Class<List<int>>(), input);
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('write writes bytes to output', () async {
      final output = ByteArrayOutputStream();
      final msg = _TestOutputMessage(output);
      final data = [10, 20, 30];
      await converter.write(data, null, msg);
      expect(output.toByteArray(), Uint8List.fromList(data));
    });
  });

  // ------------------------------------------------------------------
  // FormHttpMessageConverter
  // ------------------------------------------------------------------
  group('FormHttpMessageConverter', () {
    late FormHttpMessageConverter converter;

    setUp(() {
      converter = FormHttpMessageConverter();
    });

    test('supports application/x-www-form-urlencoded', () {
      final types = converter.getSupportedMediaTypes();
      expect(types, contains(MediaType.APPLICATION_X_WWW_FORM_URLENCODED));
    });

    test('matchesType always returns false (type is ignored for form data)', () {
      expect(converter.matchesType(Class<Map>()), isFalse);
      expect(converter.matchesType(Class<String>()), isFalse);
    });

    test('canRead returns true when media type is compatible', () {
      expect(
        converter.canRead(Class<Object>(), MediaType.APPLICATION_X_WWW_FORM_URLENCODED),
        isTrue,
      );
    });

    test('canRead returns false when media type is incompatible', () {
      expect(
        converter.canRead(Class<Object>(), MediaType.APPLICATION_JSON),
        isFalse,
      );
    });

    test('read parses simple form data', () async {
      final body = 'username=john&email=john%40example.com';
      final input = _TestInputMessage(_inputStreamFromString(body));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result['username'], 'john');
      expect(result['email'], 'john@example.com');
    });

    test('read parses empty body', () async {
      final input = _TestInputMessage(_inputStreamFromString(''));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result, isEmpty);
    });

    test('read handles URL-encoded special characters', () async {
      final body = 'name=John+Doe&message=hello%20world%21';
      final input = _TestInputMessage(_inputStreamFromString(body));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result['name'], 'John+Doe');
      expect(result['message'], 'hello world!');
    });

    test('read handles multiple values for the same key', () async {
      final body = 'color=red&color=blue&color=green';
      final input = _TestInputMessage(_inputStreamFromString(body));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result['color'], isA<List>());
      expect(result['color'], ['red', 'blue', 'green']);
    });

    test('read handles key with no value', () async {
      final body = 'empty=';
      final input = _TestInputMessage(_inputStreamFromString(body));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result['empty'], '');
    });

    test('read handles key with no equals sign', () async {
      final body = 'flag';
      final input = _TestInputMessage(_inputStreamFromString(body));
      final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
      expect(result['flag'], '');
    });

    test('write serializes Map to form-encoded string', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      final data = {'name': 'Alice', 'age': '30'};
      await converter.write(data, null, msg);
      final written = readFn();
      expect(written, contains('name=Alice'));
      expect(written, contains('age=30'));
    });

    test('write sets Content-Type header', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write({'k': 'v'}, null, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'application/x-www-form-urlencoded');
    });

    test('write encodes special characters in values', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write({'msg': 'hello world!'}, null, msg);
      final written = readFn();
      expect(written, contains('msg=hello%20world!'));
    });

    test('write handles List values', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write({'tags': ['dart', 'web']}, null, msg);
      final written = readFn();
      expect(written, contains('tags=dart'));
      expect(written, contains('tags=web'));
    });

    test('write throws HttpMessageNotWritableException for non-Map, non-String objects', () async {
      final output = ByteArrayOutputStream();
      final msg = _TestOutputMessage(output);
      expect(
        () => converter.write(42, null, msg),
        throwsA(isA<HttpMessageNotWritableException>()),
      );
    });

    test('write passes through raw String as-is', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write('raw=key&pair=value', null, msg);
      expect(readFn(), 'raw=key&pair=value');
    });
  });

  // ------------------------------------------------------------------
  // Jetson2HttpMessageConverter
  // ------------------------------------------------------------------
  group('Jetson2HttpMessageConverter', () {
    late Jetson2HttpMessageConverter converter;
    late JetsonObjectMapper objectMapper;

    setUp(() {
      objectMapper = JetsonObjectMapper();
      converter = Jetson2HttpMessageConverter(objectMapper);
    });

    test('supports application/json', () {
      final types = converter.getSupportedMediaTypes();
      expect(types, contains(MediaType.APPLICATION_JSON));
    });

    test('supports application/vnd.api+json', () {
      final types = converter.getSupportedMediaTypes();
      expect(types.any((m) => m.getMimeType() == 'application/vnd.api+json'), isTrue);
    });

    test('canRead returns true for JSON media type', () {
      expect(
        converter.canRead(Class<Object>(), MediaType.APPLICATION_JSON),
        isTrue,
      );
    });

    test('canRead returns true for vnd.api+json media type', () {
      expect(
        converter.canRead(Class<Object>(), MediaType('application', 'vnd.api+json')),
        isTrue,
      );
    });

    test('canRead returns false for non-JSON media type', () {
      expect(
        converter.canRead(Class<Object>(), MediaType.TEXT_PLAIN),
        isFalse,
      );
    });

    test('canWrite returns true for JSON media type', () {
      expect(
        converter.canWrite(Class<Object>(), MediaType.APPLICATION_JSON),
        isTrue,
      );
    });

    test('canWrite returns true when no media type is provided', () {
      expect(converter.canWrite(Class<Object>()), isTrue);
    });

    // test('read deserializes a JSON object into a Map', () async {
    //   final json = '{"name":"Alice","age":30}';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Map>(), input);
    //   expect(result, isA<Map>());
    //   final map = result as Map<String, dynamic>;
    //   expect(map['name'], 'Alice');
    //   expect(map['age'], 30);
    // });

    // test('read deserializes a JSON array into a List', () async {
    //   final json = '[1,2,3]';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Object>(), input);
    //   expect(result, [1, 2, 3]);
    // });

    // test('read deserializes a JSON string', () async {
    //   final json = '"hello"';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Object>(), input);
    //   expect(result, 'hello');
    // });

    // test('read deserializes a JSON number', () async {
    //   final json = '42';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Object>(), input);
    //   expect(result, 42);
    // });

    // test('read deserializes a JSON boolean', () async {
    //   final json = 'true';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Object>(), input);
    //   expect(result, true);
    // });

    // test('read deserializes a JSON null', () async {
    //   final json = 'null';
    //   final input = _TestInputMessage(_inputStreamFromString(json));
    //   final result = await converter.read(Class<Object>(), input);
    //   expect(result, isNull);
    // });

    test('read throws HttpMessageNotReadableException for invalid JSON', () async {
      final input = _TestInputMessage(_inputStreamFromString('{invalid'));
      expect(
        () => converter.read(Class<Object>(), input),
        throwsA(isA<HttpMessageNotReadableException>()),
      );
    });

    test('write serializes a Map to JSON', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      final data = {'key': 'value', 'number': 42};
      await converter.write(data, null, msg);
      final written = readFn();
      final decoded = jsonDecode(written) as Map<String, dynamic>;
      expect(decoded['key'], 'value');
      expect(decoded['number'], 42);
    });

    test('write serializes a List to JSON', () async {
      final (output, readFn) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write([1, 'two', 3.0], null, msg);
      final decoded = jsonDecode(readFn()) as List;
      expect(decoded, [1, 'two', 3.0]);
    });

    test('write sets Content-Type to application/json', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      await converter.write({'a': 1}, null, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'application/json');
    });

    test('write respects custom Content-Type', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      final custom = MediaType('application', 'vnd.api+json');
      await converter.write({'a': 1}, custom, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getMimeType(), 'application/vnd.api+json');
    });

    test('write with charset in Content-Type uses specified charset', () async {
      final (output, _) = _collectingOutputStream();
      final msg = _TestOutputMessage(output);
      final withCharset = MediaType('application', 'json', {'charset': 'utf-8'});
      await converter.write({'a': 1}, withCharset, msg);
      final ct = msg.getHeaders().getContentType();
      expect(ct, isNotNull);
      expect(ct!.getCharset(), 'utf-8');
    });

    // test('read respects charset from Content-Type header', () async {
    //   final json = '{"text":"café"}';
    //   final headers = HttpHeaders()
    //     ..setContentType(MediaType('application', 'json', {'charset': 'utf-8'}));
    //   final input = _TestInputMessage(_inputStreamFromString(json), headers);
    //   final result = await converter.read(Class<Object>(), input) as Map<String, dynamic>;
    //   expect(result['text'], 'café');
    // });
  });

  // ------------------------------------------------------------------
  // HttpMessageConverterRegistry & HttpMessageConverters
  // ------------------------------------------------------------------
  group('HttpMessageConverterRegistry', () {
    late HttpMessageConverters registry;

    setUp(() {
      registry = HttpMessageConverters();
    });

    test('add registers a converter', () {
      final converter = _StubConverter();
      registry.add(converter);
      final converters = registry.getMessageConverters();
      expect(converters, contains(converter));
    });

    test('add replaces duplicate converter (moves to end)', () {
      final converter = _StubConverter();
      registry.add(converter);
      registry.add(_StubConverter()); // another stub – different instance
      registry.add(converter); // re-add same instance
      final converters = registry.getMessageConverters();
      // The original converter should appear only once
      final count = converters.where((c) => identical(c, converter)).length;
      expect(count, 1);
    });

    test('getMessageConverters returns unmodifiable list', () {
      registry.add(_StubConverter());
      final converters = registry.getMessageConverters();
      expect(
        () => converters.add(_StubConverter()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('findReadable returns first matching converter', () {
      final stub = _StubConverter();
      registry.add(stub);
      final found = registry.findReadable(Class<String>(), MediaType('application', 'x-stub'));
      expect(found, same(stub));
    });

    test('findReadable returns null when no converter matches and no jetson fallback', () {
      final found = registry.findReadable(Class<int>(), MediaType('text', 'plain'));
      expect(found, isNull);
    });

    test('findWritable returns first matching converter', () {
      final stub = _StubConverter();
      registry.add(stub);
      final found = registry.findWritable(Class<String>(), MediaType('application', 'x-stub'));
      expect(found, same(stub));
    });

    test('findWritable returns null when no converter matches and no jetson fallback', () {
      final found = registry.findWritable(Class<int>(), MediaType('text', 'plain'));
      expect(found, isNull);
    });
  });

  // ------------------------------------------------------------------
  // HttpMessageConverterRegistrar integration
  // ------------------------------------------------------------------
  group('HttpMessageConverterRegistrar', () {
    test('registrar registers converters into registry', () {
      final registry = HttpMessageConverters();
      final registrar = _TestRegistrar();
      registrar.register(registry);
      final converters = registry.getMessageConverters();
      expect(converters, hasLength(2));
    });
  });

  // ------------------------------------------------------------------
  // Content negotiation edge cases
  // ------------------------------------------------------------------
  group('content negotiation edge cases', () {
    test('StringHttpMessageConverter canRead with wildcard Accept', () {
      final converter = StringHttpMessageConverter();
      expect(converter.canRead(Class<String>(), MediaType.ALL), isTrue);
    });

    test('FormHttpMessageConverter canRead with wildcard Accept', () {
      final converter = FormHttpMessageConverter();
      // matchesType is false, and wildcard is not compatible with form-urlencoded
      // in the AbstractHttpMessageConverter logic (isCompatibleWith checks type/subtype)
      // But canWrite returns true when mediaType is null
      expect(converter.canRead(Class<Object>(), MediaType.ALL), isTrue);
    });

    test('ByteArrayHttpMessageConverter canRead with wildcard type', () {
      final converter = ByteArrayHttpMessageConverter();
      expect(
        converter.canRead(Class<List<int>>(), MediaType('application', '*')),
        isTrue,
      );
    });

    test('Jetson2HttpMessageConverter canRead with charset in Content-Type', () {
      final converter = Jetson2HttpMessageConverter(JetsonObjectMapper());
      final withCharset = MediaType('application', 'json', {'charset': 'utf-8'});
      expect(converter.canRead(Class<Object>(), withCharset), isTrue);
    });
  });

  // ------------------------------------------------------------------
  // Multiple converters coexistence
  // ------------------------------------------------------------------
  group('multiple converters coexistence', () {
    late HttpMessageConverters converters;

    setUp(() {
      converters = HttpMessageConverters();
      converters.add(StringHttpMessageConverter());
      converters.add(ByteArrayHttpMessageConverter());
      converters.add(FormHttpMessageConverter());
    });

    test('findReadable selects StringHttpMessageConverter for text/plain', () {
      final found = converters.findReadable(Class<String>(), MediaType.TEXT_PLAIN);
      expect(found, isA<StringHttpMessageConverter>());
    });

    test('findReadable selects ByteArrayHttpMessageConverter for octet-stream', () {
      final found = converters.findReadable(Class<List<int>>(), MediaType.APPLICATION_OCTET_STREAM);
      expect(found, isA<ByteArrayHttpMessageConverter>());
    });

    test('findReadable selects FormHttpMessageConverter for form-urlencoded', () {
      final found = converters.findReadable(Class<Object>(), MediaType.APPLICATION_X_WWW_FORM_URLENCODED);
      expect(found, isA<FormHttpMessageConverter>());
    });

    test('findWritable selects correct converter', () {
      final jsonConverter = converters.findWritable(Class<String>(), MediaType.TEXT_PLAIN);
      expect(jsonConverter, isA<StringHttpMessageConverter>());
    });

    test('getMessageConverters returns all registered converters', () {
      expect(converters.getMessageConverters(), hasLength(3));
    });
  });

  // ------------------------------------------------------------------
  // MediaType integration with converters
  // ------------------------------------------------------------------
  group('MediaType integration', () {
    test('MediaType.parse with charset works in converter context', () {
      final mt = MediaType.parse('application/json; charset=utf-8');
      expect(mt.getCharset(), 'utf-8');
      expect(mt.getType(), 'application');
      expect(mt.getSubtype(), 'json');

      final converter = Jetson2HttpMessageConverter(JetsonObjectMapper());
      expect(converter.canRead(Class<Object>(), mt), isTrue);
    });

    test('MediaType.withCharset produces compatible type', () {
      final base = MediaType.APPLICATION_JSON;
      final withCharset = base.withCharset('utf-8');
      expect(withCharset.getCharset(), 'utf-8');
      expect(base.isCompatibleWith(withCharset), isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper classes for error-wrapping tests
// ---------------------------------------------------------------------------

class _FailingReadConverter extends AbstractHttpMessageConverter<String> {
  _FailingReadConverter() {
    super.addSupportedMediaType(MediaType('application', 'x-fail'));
  }

  @override
  bool matchesType(Class type) => type.getType() == String;

  @override
  Future<String> readInternal(Class<String> type, HttpInputMessage inputMessage) async {
    throw FormatException('intentional parse error');
  }

  @override
  Future<void> writeInternal(String object, HttpOutputMessage outputMessage) async {}

  @override
  List<Object?> equalizedProperties() => [_FailingReadConverter];
}

class _FailingWriteConverter extends AbstractHttpMessageConverter<String> {
  _FailingWriteConverter() {
    super.addSupportedMediaType(MediaType('application', 'x-fail'));
  }

  @override
  bool matchesType(Class type) => type.getType() == String;

  @override
  Future<String> readInternal(Class<String> type, HttpInputMessage inputMessage) async => '';

  @override
  Future<void> writeInternal(String object, HttpOutputMessage outputMessage) async {
    throw IOException('intentional write error');
  }

  @override
  List<Object?> equalizedProperties() => [_FailingWriteConverter];
}

class _TestRegistrar implements HttpMessageConverterRegistrar {
  @override
  void register(HttpMessageConverterRegistry registry) {
    registry.add(_StubConverter());
    registry.add(_AnotherStubConverter());
  }
}

class _AnotherStubConverter extends AbstractHttpMessageConverter<int> {
  _AnotherStubConverter() {
    super.addSupportedMediaType(MediaType('application', 'x-another'));
  }

  @override
  bool matchesType(Class type) => type.getType() == int;

  @override
  Future<int> readInternal(Class<int> type, HttpInputMessage inputMessage) async => 0;

  @override
  Future<void> writeInternal(int object, HttpOutputMessage outputMessage) async {}

  @override
  List<Object?> equalizedProperties() => [_AnotherStubConverter];
}
