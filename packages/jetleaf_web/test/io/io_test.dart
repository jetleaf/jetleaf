import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_web/io.dart';
import 'package:jetleaf_web/src/exception/exceptions.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/server/multipart/part.dart';
import 'package:jetleaf_web/src/utils/encoding.dart';

// ---------------------------------------------------------------------------
// Helpers — Multipart body builders
// ---------------------------------------------------------------------------

Uint8List _buildTextFieldBody(String boundary, String name, String value) {
  return Uint8List.fromList(utf8.encode(
    '--$boundary\r\n'
    'Content-Disposition: form-data; name="$name"\r\n'
    '\r\n'
    '$value\r\n'
    '--$boundary--\r\n',
  ));
}

Uint8List _buildFileFieldBody(
  String boundary,
  String fieldName,
  String filename,
  List<int> fileContent, {
  String contentType = 'application/octet-stream',
}) {
  return Uint8List.fromList(utf8.encode(
    '--$boundary\r\n'
    'Content-Disposition: form-data; name="$fieldName"; filename="$filename"\r\n'
    'Content-Type: $contentType\r\n'
    '\r\n'
    '${String.fromCharCodes(fileContent)}\r\n'
    '--$boundary--\r\n',
  ));
}

Uint8List _buildMixedBody(
  String boundary, {
  String? textFieldName,
  String? textFieldValue,
  String? fileFieldName,
  String? fileName,
  List<int>? fileContent,
}) {
  final buf = StringBuffer();
  if (textFieldName != null && textFieldValue != null) {
    buf.write('--$boundary\r\n');
    buf.write('Content-Disposition: form-data; name="$textFieldName"\r\n');
    buf.write('\r\n');
    buf.write('$textFieldValue\r\n');
  }
  if (fileFieldName != null && fileName != null && fileContent != null) {
    buf.write('--$boundary\r\n');
    buf.write('Content-Disposition: form-data; name="$fileFieldName"; '
        'filename="$fileName"\r\n');
    buf.write('Content-Type: application/octet-stream\r\n');
    buf.write('\r\n');
    buf.write(String.fromCharCodes(fileContent));
    buf.write('\r\n');
  }
  buf.write('--$boundary--\r\n');
  return Uint8List.fromList(utf8.encode(buf.toString()));
}

/// Binds a localhost server, sends a request to it, and returns the server
/// plus the captured [HttpRequest] received by the handler.
///
/// The server is NOT closed — the caller must close it.
Future<(HttpServer server, HttpRequest captured)> _setupServer({
  String method = 'GET',
  String path = '/',
  Map<String, String>? headers,
  List<int>? body,
  String? query,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  final completer = Completer<HttpRequest>();

  server.listen((req) {
    if (!completer.isCompleted) completer.complete(req);
    req.drain().then((_) => req.response.close());
  });

  final client = HttpClient();
  final uriPath = '$path${query != null ? '?$query' : ''}';
  final req = await client.openUrl(
    method,
    Uri.parse('http://127.0.0.1:$port$uriPath'),
  );
  headers?.forEach(req.headers.set);
  if (body != null) {
    req.headers.contentLength = body.length;
    req.add(body);
  }
  final resp = await req.close();
  await resp.drain();

  final captured = await completer.future;
  return (server, captured);
}

/// Sends a multipart POST request and returns the server + captured request.
Future<(HttpServer server, HttpRequest captured)> _setupMultipartServer({
  required String boundary,
  required List<int> body,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  final completer = Completer<HttpRequest>();

  server.listen((req) {
    if (!completer.isCompleted) completer.complete(req);
    req.drain().then((_) => req.response.close());
  });

  final client = HttpClient();
  final req = await client.openUrl(
    'POST',
    Uri.parse('http://127.0.0.1:$port/upload'),
  );
  req.headers.contentType = ContentType(
    'multipart',
    'form-data',
    charset: 'utf-8',
  );
  req.headers.set('boundary', boundary);
  // Manually set the full Content-Type with boundary
  req.headers.removeAll('Content-Type');
  req.headers.add('Content-Type', 'multipart/form-data; boundary=$boundary');
  req.add(body);
  final resp = await req.close();
  await resp.drain();

  final captured = await completer.future;
  return (server, captured);
}

// ===========================================================================
// IoPart Tests
// ===========================================================================

void main() {
  late BasicEncodingDecoder encodingDecoder;

  setUp(() {
    encodingDecoder = const BasicEncodingDecoder();
  });

  group('IoPart', () {
    test('getName returns name from Content-Disposition header', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="username"'],
      };
      final part = IoPart(headers, Uint8List.fromList(utf8.encode('john')), encodingDecoder);
      expect(part.getName(), 'username');
    });

    test('getSubmittedFileName returns filename when present', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="avatar"; filename="photo.png"'],
        'content-type': ['image/png'],
      };
      final part = IoPart(headers, Uint8List.fromList([0x89, 0x50]), encodingDecoder);
      expect(part.getSubmittedFileName(), 'photo.png');
    });

    test('getSubmittedFileName returns null for non-file part', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="bio"'],
      };
      final part = IoPart(headers, Uint8List.fromList(utf8.encode('Hello')), encodingDecoder);
      expect(part.getSubmittedFileName(), isNull);
    });

    test('getSize returns byte length of data', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="data"'],
      };
      final part = IoPart(headers, Uint8List.fromList([1, 2, 3, 4, 5]), encodingDecoder);
      expect(part.getSize(), 5);
    });

    test('getBytes returns a copy of the raw data', () async {
      final data = Uint8List.fromList([10, 20, 30]);
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="data"'],
      };
      final part = IoPart(headers, data, encodingDecoder);

      final bytes = await part.getBytes();
      expect(bytes, [10, 20, 30]);
      expect(identical(bytes, data), isFalse);
    });

    test('getString decodes content using the encoding decoder', () async {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="message"'],
      };
      final part = IoPart(headers, Uint8List.fromList(utf8.encode('Hello World')), encodingDecoder);
      expect(await part.getString(), 'Hello World');
    });

    test('getInputStream returns readable stream of part data', () async {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="field"'],
      };
      final part = IoPart(headers, Uint8List.fromList(utf8.encode('stream-data')), encodingDecoder);
      final bytes = await part.getInputStream().readAll();
      expect(utf8.decode(bytes), 'stream-data');
    });

    test('toString includes name, filename, and size', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="file"; filename="doc.txt"'],
      };
      final part = IoPart(headers, Uint8List.fromList(utf8.encode('content')), encodingDecoder);
      final str = part.toString();
      expect(str, contains('file'));
      expect(str, contains('doc.txt'));
      expect(str, contains('7'));
    });

    test('empty name defaults to empty string when no name param', () {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data'],
      };
      final part = IoPart(headers, Uint8List.fromList([0]), encodingDecoder);
      expect(part.getName(), '');
    });

    test('missing Content-Disposition header defaults name and filename', () {
      final part = IoPart(<String, List<String>>{}, Uint8List.fromList([0]), encodingDecoder);
      expect(part.getName(), '');
      expect(part.getSubmittedFileName(), isNull);
    });
  });

  // ===========================================================================
  // FilePart Tests
  // ===========================================================================

  group('FilePart', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('filepart_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('getName and getSubmittedFileName return constructor values', () async {
      final file = File('${tempDir.path}/test.txt');
      await file.writeAsBytes(utf8.encode('test content'));
      final part = FilePart('document', 'test.txt', file, encodingDecoder);
      expect(part.getName(), 'document');
      expect(part.getSubmittedFileName(), 'test.txt');
    });

    test('getSize returns file byte length', () async {
      final file = File('${tempDir.path}/data.bin');
      await file.writeAsBytes(List<int>.generate(256, (i) => i));
      final part = FilePart('data', 'data.bin', file, encodingDecoder);
      expect(part.getSize(), 256);
    });

    test('getFile returns the underlying File', () async {
      final file = File('${tempDir.path}/ref.txt');
      await file.writeAsBytes([1, 2, 3]);
      final part = FilePart('f', 'ref.txt', file, encodingDecoder);
      expect(part.getFile(), same(file));
    });

    test('getBytes reads file content asynchronously', () async {
      final file = File('${tempDir.path}/bytes.bin');
      await file.writeAsBytes([0xDE, 0xAD, 0xBE, 0xEF]);
      final part = FilePart('bin', 'bytes.bin', file, encodingDecoder);
      expect(await part.getBytes(), [0xDE, 0xAD, 0xBE, 0xEF]);
    });

    test('getString decodes file content', () async {
      final file = File('${tempDir.path}/text.txt');
      await file.writeAsBytes(utf8.encode('decoded text'));
      final part = FilePart('txt', 'text.txt', file, encodingDecoder);
      expect(await part.getString(), 'decoded text');
    });

    test('getInputStream returns readable stream of file data', () async {
      final file = File('${tempDir.path}/stream.txt');
      await file.writeAsBytes(utf8.encode('stream-me'));
      final part = FilePart('s', 'stream.txt', file, encodingDecoder);
      final bytes = await part.getInputStream().readAll();
      expect(utf8.decode(bytes), 'stream-me');
    });

    test('write copies file to target path', () async {
      final src = File('${tempDir.path}/src.txt');
      await src.writeAsBytes(utf8.encode('original'));
      final part = FilePart('s', 'src.txt', src, encodingDecoder);
      await part.write('${tempDir.path}/dest.txt');
      expect(await File('${tempDir.path}/dest.txt').readAsString(), 'original');
    });

    test('delete removes the underlying file', () async {
      final file = File('${tempDir.path}/deleteme.txt');
      await file.writeAsBytes([1]);
      final part = FilePart('d', 'deleteme.txt', file, encodingDecoder);
      expect(await file.exists(), isTrue);
      await part.delete();
      expect(await file.exists(), isFalse);
    });

    test('delete is safe when file does not exist', () async {
      final file = File('${tempDir.path}/nonexistent.txt');
      final part = FilePart('n', 'nonexistent.txt', file, encodingDecoder);
      await part.delete(); // should not throw
    });

    test('toString includes metadata', () async {
      final file = File('${tempDir.path}/meta.txt');
      await file.writeAsBytes(utf8.encode('meta'));
      final part = FilePart('m', 'meta.txt', file, encodingDecoder);
      final str = part.toString();
      expect(str, contains('m'));
      expect(str, contains('meta.txt'));
      expect(str, contains('FilePart'));
    });
  });

  // ===========================================================================
  // IoMultipartFile Tests
  // ===========================================================================

  group('IoMultipartFile', () {
    test('getName returns form field name', () {
      final stream = ByteArrayInputStream(Uint8List.fromList([1, 2, 3]));
      final file = IoMultipartFile(stream, 'avatar', 'pic.jpg', 3);
      expect(file.getName(), 'avatar');
    });

    test('getOriginalFilename returns client filename', () {
      final stream = ByteArrayInputStream(Uint8List.fromList([1]));
      final file = IoMultipartFile(stream, 'doc', 'report.pdf', 1);
      expect(file.getOriginalFilename(), 'report.pdf');
    });

    test('getSize returns byte count', () {
      final stream = ByteArrayInputStream(Uint8List(1024));
      final file = IoMultipartFile(stream, 'data', 'big.bin', 1024);
      expect(file.getSize(), 1024);
    });

    test('isEmpty returns true for zero-size file', () {
      final stream = ByteArrayInputStream(Uint8List(0));
      final file = IoMultipartFile(stream, 'empty', '', 0);
      expect(file.isEmpty(), isTrue);
    });

    test('isEmpty returns false for non-empty file', () {
      final stream = ByteArrayInputStream(Uint8List.fromList([1]));
      final file = IoMultipartFile(stream, 'f', 'f.txt', 1);
      expect(file.isEmpty(), isFalse);
    });

    test('getInputStream returns the wrapped input stream', () async {
      final data = Uint8List.fromList(utf8.encode('hello'));
      final file = IoMultipartFile(ByteArrayInputStream(data), 'g', 'g.txt', data.length);
      final result = await file.getInputStream().readAll();
      expect(utf8.decode(result), 'hello');
    });

    test('transferTo writes all bytes to output stream', () async {
      final data = Uint8List.fromList([10, 20, 30, 40, 50]);
      final file = IoMultipartFile(ByteArrayInputStream(data), 't', 't.bin', data.length);
      final output = ByteArrayOutputStream();
      await file.transferTo(output);
      expect(output.isClosed, isFalse);
    });
  });

  // ===========================================================================
  // IoMultipartRequest Tests (uses real HttpRequest via _setupServer)
  // ===========================================================================

  group('IoMultipartRequest', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('getParts returns unmodifiable list of parts', () async {
      final (s, req) = await _setupServer();
      server = s;

      final partHeaders = <String, List<String>>{
        'content-disposition': ['form-data; name="field"'],
      };
      final part = IoPart(partHeaders, Uint8List.fromList(utf8.encode('value')), encodingDecoder);

      final multipartReq = IoMultipartRequest(
        req, 1024 * 10, 1024 * 1024 * 50, 1024 * 1024 * 10,
        {}, [part], {},
      );

      final parts = multipartReq.getParts();
      expect(parts.length, 1);
      expect(parts.first.getName(), 'field');
      expect(() => parts.add(part), throwsUnsupportedError);
    });

    test('getFile returns first file for a given name', () async {
      final (s, req) = await _setupServer();
      server = s;

      final file1 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([1])), 'avatar', 'a.jpg', 1);
      final file2 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([2])), 'avatar', 'b.jpg', 1);

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024,
        {'avatar': [file1, file2]}, [], {},
      );
      expect(multipartReq.getFile('avatar'), same(file1));
    });

    test('getFile returns null for missing name', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {});
      expect(multipartReq.getFile('missing'), isNull);
    });

    test('getFiles returns list of files for a given name', () async {
      final (s, req) = await _setupServer();
      server = s;

      final file1 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([1])), 'docs', 'a.pdf', 1);
      final file2 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([2])), 'docs', 'b.pdf', 1);

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024,
        {'docs': [file1, file2]}, [], {},
      );
      expect(multipartReq.getFiles('docs'), [file1, file2]);
    });

    test('getFiles returns empty list for missing name', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {});
      expect(multipartReq.getFiles('missing'), isEmpty);
    });

    test('getFileNames returns set of file field names', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024,
        {'avatar': [], 'document': []}, [], {},
      );
      expect(multipartReq.getFileNames(), containsAll(['avatar', 'document']));
    });

    test('getFileMap returns first file per field name', () async {
      final (s, req) = await _setupServer();
      server = s;

      final file = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([1])), 'img', 'photo.png', 1);
      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024,
        {'img': [file]}, [], {},
      );
      final map = multipartReq.getFileMap();
      expect(map.length, 1);
      expect(map['img'], same(file));
    });

    test('getMultiFileMap returns all files per field', () async {
      final (s, req) = await _setupServer();
      server = s;

      final f1 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([1])), 'a', '1.bin', 1);
      final f2 = IoMultipartFile(ByteArrayInputStream(Uint8List.fromList([2])), 'a', '2.bin', 1);
      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024,
        {'a': [f1, f2]}, [], {},
      );
      expect(multipartReq.getMultiFileMap()['a']!.length, 2);
    });

    test('getPart returns part matching name case-insensitively', () async {
      final (s, req) = await _setupServer();
      server = s;

      final partHeaders = <String, List<String>>{
        'content-disposition': ['form-data; name="UserName"'],
      };
      final part = IoPart(partHeaders, Uint8List(0), encodingDecoder);
      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024, {}, [part], {},
      );
      expect(multipartReq.getPart('username'), same(part));
    });

    test('getPart returns null when no matching part', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {});
      expect(multipartReq.getPart('nope'), isNull);
    });

    test('getMaxUploadSize returns configured value', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 1024, 5 * 1024 * 1024, 1024 * 1024, {}, [], {});
      expect(multipartReq.getMaxUploadSize(), 5 * 1024 * 1024);
    });

    test('getMaxUploadSizePerFile returns configured value', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 1024, 5 * 1024 * 1024, 2 * 1024 * 1024, {}, [], {});
      expect(multipartReq.getMaxUploadSizePerFile(), 2 * 1024 * 1024);
    });

    test('getFileSizeThreshold returns configured value', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(req, 4096, 1024 * 1024, 1024 * 1024, {}, [], {});
      expect(multipartReq.getFileSizeThreshold(), 4096);
    });

    test('getParameter returns multipart param value first', () async {
      final (s, req) = await _setupServer();
      server = s;

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {'username': ['alice']},
      );
      expect(multipartReq.getParameter('username'), 'alice');
    });

    test('getParameterValues combines multipart and query params', () async {
      final (s, req) = await _setupServer(query: 'color=red');
      server = s;

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {'tag': ['dart']},
      );
      final values = multipartReq.getParameterValues('tag');
      expect(values, contains('dart'));
    });

    test('getParameterMap merges multipart and query params', () async {
      final (s, req) = await _setupServer(query: 'x=1');
      server = s;

      final multipartReq = IoMultipartRequest(
        req, 1024, 1024 * 1024, 1024 * 1024, {}, [], {'y': ['2']},
      );
      final map = multipartReq.getParameterMap();
      expect(map.containsKey('y'), isTrue);
      expect(map['y'], contains('2'));
    });
  });

  // ===========================================================================
  // MultipartParser — Boundary Extraction Tests
  // ===========================================================================

  group('MultipartParser (via test subclass)', () {
    late _TestMultipartParser parser;

    setUp(() {
      parser = _TestMultipartParser(encodingDecoder);
    });

    test('extractBoundary extracts boundary from Content-Type', () {
      expect(
        parser.testExtractBoundary('multipart/form-data; boundary=----WebKitFormBoundary'),
        '----WebKitFormBoundary',
      );
    });

    test('extractBoundary removes quotes around boundary', () {
      expect(
        parser.testExtractBoundary('multipart/form-data; boundary="abc123"'),
        'abc123',
      );
    });

    test('extractBoundary returns null when no boundary present', () {
      expect(parser.testExtractBoundary('application/json'), isNull);
    });

    test('extractBoundary handles multiple params', () {
      expect(
        parser.testExtractBoundary('multipart/form-data; charset=utf-8; boundary=XYZ'),
        'XYZ',
      );
    });

    test('extractBoundary handles trailing whitespace', () {
      expect(
        parser.testExtractBoundary('multipart/form-data;   boundary=TRIMMED  '),
        'TRIMMED',
      );
    });
  });

  // ===========================================================================
  // MultipartParser — Content Extraction Tests
  // ===========================================================================

  group('MultipartParser - parse()', () {
    late _TestMultipartParser parser;

    setUp(() {
      parser = _TestMultipartParser(encodingDecoder);
    });

    test('parses a single text field', () async {
      final boundary = 'test-boundary';
      final body = _buildTextFieldBody(boundary, 'username', 'alice');
      final parts = await parser.testParse(
        ByteArrayInputStream(body), boundary, 'utf-8',
      );
      expect(parts.length, 1);
      expect(parts[0].getName(), 'username');
      expect(await parts[0].getString(), 'alice');
    });

    test('parses a file part with content', () async {
      final boundary = 'file-boundary';
      final fileBytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F]; // "Hello"
      final body = _buildFileFieldBody(boundary, 'file', 'hello.txt', fileBytes);
      final parts = await parser.testParse(
        ByteArrayInputStream(body), boundary, 'utf-8',
      );
      expect(parts.length, 1);
      expect(parts[0].getName(), 'file');
      expect(parts[0].getSubmittedFileName(), 'hello.txt');
      expect(await parts[0].getBytes(), fileBytes);
    });

    test('parses mixed text and file parts', () async {
      final boundary = 'mixed-boundary';
      final body = _buildMixedBody(
        boundary,
        textFieldName: 'description',
        textFieldValue: 'A test file',
        fileFieldName: 'upload',
        fileName: 'test.bin',
        fileContent: [0xCA, 0xFE],
      );
      final parts = await parser.testParse(
        ByteArrayInputStream(body), boundary, 'utf-8',
      );
      expect(parts.length, 2);

      final textPart = parts.firstWhere((p) => p.getName() == 'description');
      expect(await textPart.getString(), 'A test file');

      final filePart = parts.firstWhere((p) => p.getName() == 'upload');
      expect(filePart.getSubmittedFileName(), 'test.bin');
      expect(await filePart.getBytes(), [0xC3, 0x8A, 0xC3, 0xBE]);
    });

    test('throws MultipartParseException when no boundary found', () async {
      final body = Uint8List.fromList(utf8.encode('no boundary here'));
      expect(
        () => parser.testParse(
          ByteArrayInputStream(body), 'nonexistent', 'utf-8',
        ),
        throwsA(isA<MultipartParseException>()),
      );
    });

    test('reads exact number of bytes when contentLength provided', () async {
      final boundary = 'cl-boundary';
      final body = _buildTextFieldBody(boundary, 'field', 'val');
      final parts = await parser.testParse(
        ByteArrayInputStream(body), boundary, 'utf-8', body.length,
      );
      expect(parts.length, 1);
      expect(await parts[0].getString(), 'val');
    });
  });

  // ===========================================================================
  // EncodingDecoder — BasicEncodingDecoder Tests
  // ===========================================================================

  group('BasicEncodingDecoder', () {
    late BasicEncodingDecoder decoder;

    setUp(() {
      decoder = const BasicEncodingDecoder();
    });

    test('decode UTF-8 bytes', () {
      expect(
        decoder.decode(Uint8List.fromList(utf8.encode('Hello, World!'))),
        'Hello, World!',
      );
    });

    test('decode ASCII bytes', () {
      expect(
        decoder.decode(Uint8List.fromList([72, 101, 108, 108, 111]), encodingString: 'ascii'),
        'Hello',
      );
    });

    test('decode latin-1 bytes', () {
      expect(
        decoder.decode(Uint8List.fromList([0xE9]), encodingString: 'latin-1'),
        '\u00e9',
      );
    });

    test('decode with explicit Encoding parameter', () {
      expect(
        decoder.decode(Uint8List.fromList(utf8.encode('test')), encoding: utf8),
        'test',
      );
    });

    test('encode string to UTF-8 bytes', () {
      expect(decoder.encode('Hi'), utf8.encode('Hi'));
    });

    test('encode with explicit Encoding parameter', () {
      expect(decoder.encode('X', encoding: ascii), [0x58]);
    });

    test('supportsEncoding returns true for utf-8', () {
      expect(decoder.supportsEncoding('utf-8'), isTrue);
    });

    test('supportsEncoding returns true for ascii', () {
      expect(decoder.supportsEncoding('ascii'), isTrue);
    });

    test('supportsEncoding returns true for latin-1', () {
      expect(decoder.supportsEncoding('latin-1'), isTrue);
    });

    test('supportsEncoding returns false for unknown encoding', () {
      expect(decoder.supportsEncoding('xyz-123'), isFalse);
    });

    test('getSupportedEncodings returns list of known encodings', () {
      final encodings = decoder.getSupportedEncodings();
      expect(encodings, containsAll(['utf-8', 'ascii', 'latin-1']));
    });
  });

  // ===========================================================================
  // IoEncodingDecoder Tests
  // ===========================================================================

  group('IoEncodingDecoder', () {
    late IoEncodingDecoder decoder;

    setUp(() {
      decoder = IoEncodingDecoder();
    });

    test('decode falls back to BasicEncodingDecoder for standard encodings', () {
      expect(
        decoder.decode(Uint8List.fromList(utf8.encode('fallback')), encodingString: 'utf-8'),
        'fallback',
      );
    });

    test('encode falls back to BasicEncodingDecoder', () {
      expect(
        decoder.encode('test-encode', encodingString: 'utf-8'),
        utf8.encode('test-encode'),
      );
    });

    test('supportsEncoding delegates to fallback', () {
      expect(decoder.supportsEncoding('utf-8'), isTrue);
    });

    test('getSupportedEncodings includes fallback encodings', () {
      expect(decoder.getSupportedEncodings(), contains('utf-8'));
    });

    test('custom handler is used when registered', () {
      decoder.registerHandler(_ReverseEncodingDecoder());
      final bytes = Uint8List.fromList([0x41, 0x42, 0x43]); // "ABC"
      expect(decoder.decode(bytes, encodingString: 'reverse'), 'CBA');
    });

    test('removeHandler removes previously registered handler', () {
      final handler = _ReverseEncodingDecoder();
      decoder.registerHandler(handler);
      decoder.removeHandler(handler);

      final bytes = Uint8List.fromList([0x41]);
      final result = decoder.decode(bytes, encodingString: 'reverse');
      expect(result, 'A');
    });

    test('decode with explicit Encoding parameter ignores custom handlers', () {
      decoder.registerHandler(_ReverseEncodingDecoder());
      expect(
        decoder.decode(Uint8List.fromList(utf8.encode('explicit')), encoding: utf8),
        'explicit',
      );
    });
  });

  // ===========================================================================
  // IoMultipartResolver — isMultipart Tests (integration with real requests)
  // ===========================================================================

  group('IoMultipartResolver - isMultipart (integration)', () {
    late IoMultipartResolver resolver;
    late HttpServer server;

    setUp(() {
      resolver = IoMultipartResolver(encodingDecoder);
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('isMultipart returns true for POST with multipart/form-data', () async {
      final boundary = 'test-boundary';
      final body = _buildTextFieldBody(boundary, 'field', 'value');
      final (s, req) = await _setupMultipartServer(boundary: boundary, body: body);
      server = s;

      final ioReq = IoRequest(req);
      expect(resolver.isMultipart(ioReq), isTrue);
    });

    test('isMultipart returns false for GET request', () async {
      final (s, req) = await _setupServer(method: 'GET');
      server = s;

      final ioReq = IoRequest(req);
      expect(resolver.isMultipart(ioReq), isFalse);
    });

    test('isMultipart returns false for POST without multipart content-type', () async {
      final (s, req) = await _setupServer(
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: utf8.encode('{"key":"value"}'),
      );
      server = s;

      final ioReq = IoRequest(req);
      expect(resolver.isMultipart(ioReq), isFalse);
    });
  });

  // ===========================================================================
  // HttpStatus usage in IO context
  // ===========================================================================

  group('HttpStatus in IO context', () {
    test('OK has code 200 and is 2xx', () {
      expect(HttpStatus.OK.getCode(), 200);
      expect(HttpStatus.OK.is2xxSuccessful(), isTrue);
    });

    test('NOT_FOUND has code 404 and is 4xx', () {
      expect(HttpStatus.NOT_FOUND.getCode(), 404);
      expect(HttpStatus.NOT_FOUND.is4xxClientError(), isTrue);
    });

    test('CREATED has code 201 and is 2xx', () {
      expect(HttpStatus.CREATED.getCode(), 201);
      expect(HttpStatus.CREATED.is2xxSuccessful(), isTrue);
    });

    test('NO_CONTENT has code 204 and is 2xx', () {
      expect(HttpStatus.NO_CONTENT.getCode(), 204);
      expect(HttpStatus.NO_CONTENT.is2xxSuccessful(), isTrue);
    });

    test('INTERNAL_SERVER_ERROR has code 500 and is 5xx', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.getCode(), 500);
      expect(HttpStatus.INTERNAL_SERVER_ERROR.is5xxServerError(), isTrue);
    });

    test('BAD_REQUEST has code 400 and is 4xx', () {
      expect(HttpStatus.BAD_REQUEST.getCode(), 400);
      expect(HttpStatus.BAD_REQUEST.is4xxClientError(), isTrue);
    });

    test('fromCode returns dynamic status for unknown code', () {
      final status = HttpStatus.fromCode(777);
      expect(status.getCode(), 777);
      expect(status.getName(), 'UNKNOWN_777');
    });
  });

  // ===========================================================================
  // HttpMethod Tests
  // ===========================================================================

  group('HttpMethod', () {
    test('FROM creates method from string', () {
      expect(HttpMethod.FROM('GET'), equals(HttpMethod.GET));
      expect(HttpMethod.FROM('post'), equals(HttpMethod.POST));
    });

    test('matches is case-insensitive', () {
      expect(HttpMethod.GET.matches('GET'), isTrue);
      expect(HttpMethod.GET.matches('get'), isTrue);
      expect(HttpMethod.GET.matches('Get'), isTrue);
      expect(HttpMethod.GET.matches('POST'), isFalse);
    });

    test('toString returns uppercased method string', () {
      expect(HttpMethod.GET.toString(), 'GET');
      expect(HttpMethod.POST.toString(), 'POST');
    });

    test('valueOf creates from upper case string', () {
      expect(HttpMethod.valueOf('PUT'), equals(HttpMethod.PUT));
    });

    test('getMethods returns all standard methods', () {
      final methods = HttpMethod.getMethods();
      expect(methods, containsAll([
        HttpMethod.GET, HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE,
        HttpMethod.HEAD, HttpMethod.OPTIONS, HttpMethod.TRACE,
        HttpMethod.CONNECT, HttpMethod.PATCH,
      ]));
    });
  });

  // ===========================================================================
  // MediaType parsing for multipart context
  // ===========================================================================

  group('MediaType parsing for multipart', () {
    test('parse multipart/form-data with boundary', () {
      final mt = MediaType.parse('multipart/form-data; boundary=----abc');
      expect(mt.getType(), 'multipart');
      expect(mt.getSubtype(), 'form-data');
      expect(mt.getParameters()['boundary'], '----abc');
    });

    test('isCompatibleWith MULTIPART_FORM_DATA', () {
      final mt = MediaType.parse('multipart/form-data; boundary=xyz');
      expect(mt.isCompatibleWith(MediaType.MULTIPART_FORM_DATA), isTrue);
    });

    test('MULTIPART_FORM_DATA_WITH_BOUNDARY has boundary param', () {
      expect(
        MediaType.MULTIPART_FORM_DATA_WITH_BOUNDARY.getParameters()['boundary'],
        '----ZapClientBoundary',
      );
    });

    test('multipartFormDataWithBoundary factory creates correct type', () {
      final mt = MediaType.multipartFormDataWithBoundary('my-boundary');
      expect(mt.getType(), 'multipart');
      expect(mt.getSubtype(), 'form-data');
      expect(mt.getParameters()['boundary'], 'my-boundary');
    });
  });

  // ===========================================================================
  // IoPart — write to file
  // ===========================================================================

  group('IoPart - write', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('iopart_write_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('write saves part data to file', () async {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="upload"'],
      };
      final data = Uint8List.fromList(utf8.encode('file content'));
      final part = IoPart(headers, data, encodingDecoder);

      final path = '${tempDir.path}/output.txt';
      await part.write(path);

      expect(await File(path).readAsString(), 'file content');
    });

    test('write throws on invalid path', () async {
      final headers = <String, List<String>>{
        'content-disposition': ['form-data; name="f"'],
      };
      final part = IoPart(headers, Uint8List(1), encodingDecoder);

      expect(
        () => part.write('/nonexistent/deeply/nested/path.txt'),
        throwsA(isA<Exception>()),
      );
    });

    test('delete on IoPart is a no-op (in-memory)', () async {
      final part = IoPart(
        <String, List<String>>{'content-disposition': ['form-data; name="x"']},
        Uint8List(1),
        encodingDecoder,
      );
      await part.delete(); // should not throw
    });
  });

  // ===========================================================================
  // IoRequest — integration tests with real server
  // ===========================================================================

  group('IoRequest (integration)', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('getMethod returns correct HTTP method', () async {
      final (s, req) = await _setupServer(method: 'POST');
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getMethod(), equals(HttpMethod.POST));
    });

    test('getRequestURI returns request URI', () async {
      final (s, req) = await _setupServer(path: '/api/users');
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getRequestURI().path, '/api/users');
    });

    test('getQueryString returns query string', () async {
      final (s, req) = await _setupServer(query: 'page=1&limit=10');
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getQueryString(), 'page=1&limit=10');
    });

    test('getParameter returns query parameter value', () async {
      final (s, req) = await _setupServer(query: 'name=john');
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getParameter('name'), 'john');
    });

    test('getParameterValues returns all values for multi-valued param', () async {
      final (s, req) = await _setupServer(query: 'tag=a&tag=b');
      server = s;

      final ioReq = IoRequest(req);
      final values = ioReq.getParameterValues('tag');
      expect(values, containsAll(['a', 'b']));
    });

    test('getAttribute/setAttribute round-trips correctly', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      ioReq.setAttribute('userId', 42);
      expect(ioReq.getAttribute('userId'), 42);
    });

    test('removeAttribute removes stored attribute', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      ioReq.setAttribute('temp', 'value');
      ioReq.removeAttribute('temp');
      expect(ioReq.getAttribute('temp'), isNull);
    });

    test('getAttributeNames returns set of attribute names', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      ioReq.setAttribute('a', 1);
      ioReq.setAttribute('b', 2);
      expect(ioReq.getAttributeNames(), containsAll(['a', 'b']));
    });

    test('getContextPath/setContextPath round-trips correctly', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      ioReq.setContextPath('/api');
      expect(ioReq.getContextPath(), '/api');
    });

    test('getContentLength returns content length', () async {
      final body = utf8.encode('hello');
      final (s, req) = await _setupServer(method: 'POST', body: body);
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getContentLength(), body.length);
    });

    test('getCreatedAt/setCreatedAt round-trips', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      final now = DateTime(2025, 1, 1);
      ioReq.setCreatedAt(now);
      expect(ioReq.getCreatedAt(), now);
    });

    test('getCompletedAt/setCompletedAt round-trips', () async {
      final (s, req) = await _setupServer();
      server = s;

      final ioReq = IoRequest(req);
      expect(ioReq.getCompletedAt(), isNull);
      final now = DateTime(2025, 6, 15);
      ioReq.setCompletedAt(now);
      expect(ioReq.getCompletedAt(), now);
    });
  });
}

// ===========================================================================
// Mock / Test-only Types
// ===========================================================================

/// Exposes protected methods of [AbstractMultipartParser] for testing.
class _TestMultipartParser extends _TestAbstractMultipartParser {
  _TestMultipartParser(super.decoder);

  String? testExtractBoundary(String contentType) => extractBoundary(contentType);

  Future<List<Part>> testParse(
    InputStream stream,
    String boundary,
    String charset, [
    int? contentLength,
  ]) => parse(stream, boundary, charset, contentLength);
}

/// Concrete [AbstractMultipartParser] for test purposes.
class _TestAbstractMultipartParser extends AbstractMultipartParser {
  final EncodingDecoder _decoder;
  _TestAbstractMultipartParser(this._decoder);

  @override
  EncodingDecoder getEncodingDecoder() => _decoder;

  @override
  Log getLog() => Log('TestMultipartParser', canPublish: false);

  @override
  int getBufferSize() => MultipartParser.DEFAULT_BUFFER_SIZE;

  @override
  int getFileSizeThreshold() => 1024 * 10;

  @override
  bool getPreserveFileName() => true;

  @override
  String getTemporaryDirectory() => Directory.systemTemp.path;
}

/// Custom encoding handler for testing IoEncodingDecoder registration.
/// Reverses byte arrays for test purposes.
class _ReverseEncodingDecoder implements EncodingDecoder {
  @override
  String decode(Uint8List bytes, {String encodingString = 'utf-8', Encoding? encoding}) {
    return String.fromCharCodes(bytes.toList().reversed);
  }

  @override
  Uint8List encode(String text, {String encodingString = 'utf-8', Encoding? encoding}) {
    return Uint8List.fromList(text.codeUnits.reversed.toList());
  }

  @override
  bool supportsEncoding(String encoding) => encoding == 'reverse';

  @override
  List<String> getSupportedEncodings() => ['reverse'];
}
