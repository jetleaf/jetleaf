import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

class MemoryOutputStream extends OutputStream {
  final StringBuffer _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  Future<void> writeString(String data, [Encoding? encoding]) async {
    _buffer.write(data);
  }

  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    final slice = b.sublist(offset, length != null ? offset + length : null);
    _buffer.write(utf8.decode(slice));
  }

  @override
  Future<void> writeByte(int b) async {
    _buffer.writeCharCode(b);
  }

  @override
  Future<void> writeBytes(Uint8List data) async {
    _buffer.write(utf8.decode(data));
  }

  @override
  Future<void> writeObject(Object? obj) async {
    _buffer.write(obj?.toString() ?? '');
  }

  @override
  Future<void> flush() async {
    await super.flush();
  }

  @override
  Future<void> close() async {
    await super.close();
  }
}

class MockServerHttpRequest implements ServerHttpRequest {
  final HttpMethod _method;
  final Uri _uri;
  final HttpHeaders _headers;
  final HttpCookies _cookies;
  final HttpSession? session;
  final String origin;

  MockServerHttpRequest({
    HttpMethod? method,
    String path = '/',
    Map<String, String> headers = const {},
    List<HttpCookie> cookies = const [],
    this.session,
    this.origin = '127.0.0.1',
  })  : _method = method ?? HttpMethod.GET,
        _uri = Uri.parse(path),
        _headers = HttpHeaders(),
        _cookies = HttpCookies() {
    headers.forEach((k, v) => _headers.set(k, v));
    for (final c in cookies) {
      _cookies.addCookie(c);
    }
  }

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getRequestURI() => _uri;

  @override
  Uri getUri() => _uri;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  HttpCookies getCookies() => _cookies;

  @override
  HttpSession? getSession([bool create = true]) => session;

  @override
  String getOrigin() => origin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockServerHttpResponse implements ServerHttpResponse {
  final HttpHeaders _headers = HttpHeaders();
  final MemoryOutputStream _body = MemoryOutputStream();
  HttpStatus status = HttpStatus.OK;

  String get bodyAsString => _body.content;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setStatus(HttpStatus httpStatus) {
    status = httpStatus;
  }

  @override
  OutputStream getBody() => _body;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingFilterChain implements FilterChain {
  bool called = false;
  void Function(ServerHttpRequest request, ServerHttpResponse response)? onNext;

  RecordingFilterChain({this.onNext});

  @override
  Future<void> next(
    ServerHttpRequest request,
    ServerHttpResponse response,
  ) async {
    called = true;
    onNext?.call(request, response);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
