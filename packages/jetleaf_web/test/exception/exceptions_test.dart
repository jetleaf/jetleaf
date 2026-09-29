import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_web/src/exception/exceptions.dart';
import 'package:jetleaf_web/src/exception/path_exception.dart';
import 'package:jetleaf_web/src/exception/server_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('HttpException', () {
    test('constructs with required statusCode', () {
      final e = HttpException('msg', statusCode: 500);
      expect(e.message, 'msg');
      expect(e.statusCode, 500);
      expect(e.uri, isNull);
      expect(e.details, isNull);
      expect(e.originalException, isNull);
      expect(e.originalStackTrace, isNull);
    });

    test('constructs with all optional parameters', () {
      final uri = Uri.parse('https://example.com/api');
      final original = FormatException('bad');
      final st = StackTrace.current;
      final details = {'key': 'value'};

      final e = HttpException(
        'full',
        uri: uri,
        statusCode: 418,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.uri, uri);
      expect(e.statusCode, 418);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('toString includes message and status', () {
      final e = HttpException('oops', statusCode: 500);
      expect(e.toString(), contains('oops'));
      expect(e.toString(), contains('500'));
    });

    test('toString includes uri when set', () {
      final uri = Uri.parse('https://example.com');
      final e = HttpException('fail', uri: uri, statusCode: 404);
      expect(e.toString(), contains('https://example.com'));
    });

    test('toString includes details when non-empty', () {
      final e = HttpException(
        'err',
        statusCode: 400,
        details: {'field': 'name'},
      );
      expect(e.toString(), contains('field'));
      expect(e.toString(), contains('name'));
    });

    test('toString omits details when null', () {
      final e = HttpException('err', statusCode: 400);
      expect(e.toString(), isNot(contains('Details:')));
    });

    test('toString omits uri when null', () {
      final e = HttpException('err', statusCode: 400);
      expect(e.toString(), isNot(contains('URL:')));
    });

    test('toJson includes all fields when fully populated', () {
      final uri = Uri.parse('https://test.com');
      final original = FormatException('bad input');
      final e = HttpException(
        'msg',
        uri: uri,
        statusCode: 422,
        details: {'x': 1},
        originalException: original,
      );

      final json = e.toJson();
      expect(json['uri'], 'https://test.com');
      expect(json['status_code'], 422);
      expect(json['details'], {'x': 1});
      expect(json['original_exception'], contains('bad input'));
    });

    test('toJson omits uri when null', () {
      final e = HttpException('msg', statusCode: 400);
      final json = e.toJson();
      expect(json.containsKey('uri'), isFalse);
    });

    test('toJson omits details when null', () {
      final e = HttpException('msg', statusCode: 400);
      final json = e.toJson();
      expect(json.containsKey('details'), isFalse);
    });

    test('toJson omits original_exception when null', () {
      final e = HttpException('msg', statusCode: 400);
      final json = e.toJson();
      expect(json.containsKey('original_exception'), isFalse);
    });

    test('toMap returns expected structure', () {
      final uri = Uri.parse('https://test.com');
      final e = HttpException('msg', uri: uri, statusCode: 400, details: {'a': 1});
      final map = e.toMap();

      expect(map['type'], 'HttpException');
      expect(map['message'], 'msg');
      expect(map['uri'], 'https://test.com');
      expect(map['statusCode'], 400);
      expect(map['details'], {'a': 1});
    });

    test('getStatus returns HttpStatus for valid code', () {
      final e = HttpException('msg', statusCode: 404);
      final status = e.getStatus();
      expect(status.getCode(), 404);
    });

    test('is thrown and caught as HttpException', () {
      expect(
        () => throw HttpException('test', statusCode: 500),
        throwsA(isA<HttpException>()),
      );
    });

    test('can be caught with dynamic typing', () {
      bool caught = false;
      try {
        throw HttpException('dynamic', statusCode: 500);
      } catch (e) {
        caught = e is HttpException;
      }
      expect(caught, isTrue);
    });

    test('preserves stack trace when thrown', () {
      StackTrace? caughtTrace;
      try {
        throw HttpException('trace test', statusCode: 500);
      } catch (e, st) {
        caughtTrace = st;
      }
      expect(caughtTrace, isNotNull);
      expect(caughtTrace.toString(), isNotEmpty);
    });
  });

  group('NotFoundException', () {
    test('has default status code 404', () {
      final e = NotFoundException('not found');
      expect(e.statusCode, 404);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/users');
      final original = FormatException('parse error');
      final st = StackTrace.current;
      final details = {'route': '/api/users'};

      final e = NotFoundException(
        'user not found',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'user not found');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(NotFoundException('x'), isA<HttpException>());
    });

    test('toString contains type name and message', () {
      final e = NotFoundException('missing');
      final str = e.toString();
      expect(str, contains('NotFoundException'));
      expect(str, contains('missing'));
    });

    test('is thrown and caught as NotFoundException', () {
      expect(
        () => throw NotFoundException('gone'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('is caught when catching HttpException', () {
      bool caught = false;
      try {
        throw NotFoundException('gone');
      } on HttpException {
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('BadRequestException', () {
    test('has default status code 400', () {
      expect(BadRequestException('bad').statusCode, 400);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/data');
      final original = FormatException('invalid');
      final st = StackTrace.current;
      final details = {'field': 'email'};

      final e = BadRequestException(
        'invalid input',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'invalid input');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(BadRequestException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw BadRequestException('missing field'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('UnauthorizedException', () {
    test('has default status code 401', () {
      expect(UnauthorizedException('unauth').statusCode, 401);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/secure');
      final original = Exception('token expired');
      final st = StackTrace.current;
      final details = {'token': 'expired'};

      final e = UnauthorizedException(
        'no token',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'no token');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(UnauthorizedException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw UnauthorizedException('unauthorized'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('ForbiddenException', () {
    test('has default status code 403', () {
      expect(ForbiddenException('forbidden').statusCode, 403);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/admin');
      final original = Exception('rbac denied');
      final st = StackTrace.current;
      final details = {'role': 'viewer'};

      final e = ForbiddenException(
        'access denied',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'access denied');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(ForbiddenException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw ForbiddenException('forbidden'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('MethodNotAllowedException', () {
    test('has default status code 405', () {
      expect(MethodNotAllowedException('nope').statusCode, 405);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/users');
      final original = Exception('method check');
      final st = StackTrace.current;
      final details = {'allowed': 'GET'};

      final e = MethodNotAllowedException(
        'POST not allowed',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'POST not allowed');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(MethodNotAllowedException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw MethodNotAllowedException('method not allowed'),
        throwsA(isA<MethodNotAllowedException>()),
      );
    });
  });

  group('ConflictException', () {
    test('has default status code 409', () {
      expect(ConflictException('conflict').statusCode, 409);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/users/1');
      final original = Exception('duplicate key');
      final st = StackTrace.current;
      final details = {'constraint': 'unique_email'};

      final e = ConflictException(
        'duplicate',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'duplicate');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(ConflictException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw ConflictException('resource conflict'),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  group('InternalServerErrorException', () {
    test('has default status code 500', () {
      expect(InternalServerErrorException('ise').statusCode, 500);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/critical');
      final original = Exception('db down');
      final st = StackTrace.current;
      final details = {'service': 'database'};

      final e = InternalServerErrorException(
        'server error',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'server error');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(InternalServerErrorException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw InternalServerErrorException('internal'),
        throwsA(isA<InternalServerErrorException>()),
      );
    });
  });

  group('ServiceUnavailableException', () {
    test('has default status code 503', () {
      final e = ServiceUnavailableException();
      expect(e.statusCode, 503);
    });

    test('builds default message when no exception or details', () {
      final e = ServiceUnavailableException();
      expect(e.message, 'Unable to start web server');
    });

    test('includes original exception message in built message', () {
      final original = Exception('connection refused');
      final e = ServiceUnavailableException(originalException: original);
      expect(e.message, contains('connection refused'));
      expect(e.message, contains('Unable to start web server'));
    });

    test('extracts priority key "reason" from details', () {
      final e = ServiceUnavailableException(
        details: {'reason': 'maintenance mode'},
      );
      expect(e.message, contains('maintenance mode'));
    });

    test('extracts priority key "cause" from details', () {
      final e = ServiceUnavailableException(
        details: {'cause': 'disk full'},
      );
      expect(e.message, contains('disk full'));
    });

    test('extracts priority key "error" from details', () {
      final e = ServiceUnavailableException(
        details: {'error': 'timeout'},
      );
      expect(e.message, contains('timeout'));
    });

    test('extracts priority key "issue" from details', () {
      final e = ServiceUnavailableException(
        details: {'issue': 'memory leak'},
      );
      expect(e.message, contains('memory leak'));
    });

    test('extracts priority key "problem" from details', () {
      final e = ServiceUnavailableException(
        details: {'problem': 'high load'},
      );
      expect(e.message, contains('high load'));
    });

    test('extracts priority key "description" from details', () {
      final e = ServiceUnavailableException(
        details: {'description': 'scheduled downtime'},
      );
      expect(e.message, contains('scheduled downtime'));
    });

    test('falls back to first non-empty string value', () {
      final e = ServiceUnavailableException(
        details: {'custom_key': 'custom value'},
      );
      expect(e.message, contains('custom_key'));
      expect(e.message, contains('custom value'));
    });

    test('shows count when no string values in details', () {
      final e = ServiceUnavailableException(
        details: {'count': 42, 'flag': true},
      );
      expect(e.message, contains('2 error detail(s)'));
    });

    test('combines original exception and details', () {
      final original = Exception('db error');
      final e = ServiceUnavailableException(
        originalException: original,
        details: {'reason': 'overloaded'},
      );
      expect(e.message, contains('db error'));
      expect(e.message, contains('overloaded'));
    });

    test('truncates long exception messages', () {
      final longMessage = 'x' * 150;
      final original = Exception(longMessage);
      final e = ServiceUnavailableException(originalException: original);
      expect(e.message.length, lessThan(longMessage.length + 50));
    });

    test('cleans "Exception: " prefix', () {
      final original = Exception('Exception: cleaned');
      final e = ServiceUnavailableException(originalException: original);
      expect(e.message, contains('cleaned'));
      expect(e.message, isNot(contains('Exception: Exception:')));
    });

    test('cleans "Error: " prefix', () {
      final original = Exception('Error: cleaned');
      final e = ServiceUnavailableException(originalException: original);
      expect(e.message, contains('cleaned'));
    });

    test('constructs with uri', () {
      final uri = Uri.parse('https://api.example.com');
      final e = ServiceUnavailableException(uri: uri);
      expect(e.uri, uri);
    });

    test('constructs with original stack trace', () {
      final st = StackTrace.current;
      final e = ServiceUnavailableException(originalStackTrace: st);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(ServiceUnavailableException(), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw ServiceUnavailableException(),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });

  group('PayloadTooLargeException', () {
    test('has default status code 413', () {
      expect(PayloadTooLargeException('too big').statusCode, 413);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/upload');
      final original = Exception('size exceeded');
      final st = StackTrace.current;
      final details = {'maxBytes': 10485760};

      final e = PayloadTooLargeException(
        'file too large',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'file too large');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(PayloadTooLargeException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw PayloadTooLargeException('payload too large'),
        throwsA(isA<PayloadTooLargeException>()),
      );
    });
  });

  group('RequestTimeoutException', () {
    test('has default status code 408', () {
      expect(RequestTimeoutException('timeout').statusCode, 408);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/slow');
      final original = Exception('timed out');
      final st = StackTrace.current;
      final details = {'timeoutMs': 30000};

      final e = RequestTimeoutException(
        'request timeout',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'request timeout');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(RequestTimeoutException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw RequestTimeoutException('timed out'),
        throwsA(isA<RequestTimeoutException>()),
      );
    });
  });

  group('TooManyRequestsException', () {
    test('has default status code 429', () {
      expect(TooManyRequestsException('rate limited').statusCode, 429);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/resource');
      final original = Exception('quota exceeded');
      final st = StackTrace.current;
      final details = {'retryAfter': 60};

      final e = TooManyRequestsException(
        'too many',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'too many');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(TooManyRequestsException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw TooManyRequestsException('rate limited'),
        throwsA(isA<TooManyRequestsException>()),
      );
    });
  });

  group('PathVariableException', () {
    test('has default status code 400', () {
      expect(PathVariableException('bad var').statusCode, 400);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/users/abc');
      final original = FormatException('not a number');
      final st = StackTrace.current;
      final details = {'variable': 'id'};

      final e = PathVariableException(
        'invalid path variable',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'invalid path variable');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(PathVariableException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw PathVariableException('bad path var'),
        throwsA(isA<PathVariableException>()),
      );
    });
  });

  group('GatewayTimeoutException', () {
    test('has default status code 504', () {
      expect(GatewayTimeoutException('gw timeout').statusCode, 504);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/proxy/upstream');
      final original = Exception('upstream timeout');
      final st = StackTrace.current;
      final details = {'upstream': 'service-a'};

      final e = GatewayTimeoutException(
        'gateway timeout',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'gateway timeout');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(GatewayTimeoutException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw GatewayTimeoutException('gw timeout'),
        throwsA(isA<GatewayTimeoutException>()),
      );
    });
  });

  group('BadGatewayException', () {
    test('has default status code 502', () {
      expect(BadGatewayException('bad gw').statusCode, 502);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/proxy');
      final original = Exception('upstream error');
      final st = StackTrace.current;
      final details = {'upstream_status': 500};

      final e = BadGatewayException(
        'bad gateway',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'bad gateway');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(BadGatewayException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw BadGatewayException('bad gw'),
        throwsA(isA<BadGatewayException>()),
      );
    });
  });

  group('UnsupportedMediaTypeException', () {
    test('has default status code 415', () {
      expect(UnsupportedMediaTypeException('unsupported').statusCode, 415);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/convert');
      final original = Exception('type mismatch');
      final st = StackTrace.current;
      final details = {'contentType': 'text/xml'};

      final e = UnsupportedMediaTypeException(
        'unsupported type',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'unsupported type');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(UnsupportedMediaTypeException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw UnsupportedMediaTypeException('unsupported media'),
        throwsA(isA<UnsupportedMediaTypeException>()),
      );
    });
  });

  group('NotAcceptableException', () {
    test('has default status code 406', () {
      expect(NotAcceptableException('not acceptable').statusCode, 406);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/content');
      final original = Exception('negotiation failed');
      final st = StackTrace.current;
      final details = {'accepted': 'application/json'};

      final e = NotAcceptableException(
        'not acceptable',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'not acceptable');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(NotAcceptableException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw NotAcceptableException('not acceptable'),
        throwsA(isA<NotAcceptableException>()),
      );
    });
  });

  group('ViewResolutionException', () {
    test('has default status code 500', () {
      expect(ViewResolutionException('view error').statusCode, 500);
    });

    test('constructs with message', () {
      final e = ViewResolutionException('could not resolve view');
      expect(e.message, 'could not resolve view');
    });

    test('is a HttpException', () {
      expect(ViewResolutionException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw ViewResolutionException('view not found'),
        throwsA(isA<ViewResolutionException>()),
      );
    });

    test('toString contains message', () {
      final e = ViewResolutionException('template missing');
      expect(e.toString(), contains('template missing'));
    });
  });

  group('HttpMessageNotReadableException', () {
    test('has default status code 400', () {
      expect(HttpMessageNotReadableException('unreadable').statusCode, 400);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/body');
      final original = FormatException('malformed json');
      final st = StackTrace.current;
      final details = {'contentType': 'application/json'};

      final e = HttpMessageNotReadableException(
        'cannot read',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'cannot read');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(HttpMessageNotReadableException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw HttpMessageNotReadableException('unreadable'),
        throwsA(isA<HttpMessageNotReadableException>()),
      );
    });
  });

  group('HttpMessageNotWritableException', () {
    test('has default status code 500', () {
      expect(HttpMessageNotWritableException('unwritable').statusCode, 500);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/response');
      final original = Exception('write failed');
      final st = StackTrace.current;
      final details = {'format': 'json'};

      final e = HttpMessageNotWritableException(
        'cannot write',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'cannot write');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(HttpMessageNotWritableException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw HttpMessageNotWritableException('unwritable'),
        throwsA(isA<HttpMessageNotWritableException>()),
      );
    });
  });

  group('HttpMediaTypeNotSupportedException', () {
    test('has default status code 500', () {
      expect(
        HttpMediaTypeNotSupportedException('unsupported').statusCode,
        500,
      );
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/upload');
      final original = Exception('type error');
      final st = StackTrace.current;
      final details = {'supported': 'application/json'};

      final e = HttpMediaTypeNotSupportedException(
        'media type not supported',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'media type not supported');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(
        HttpMediaTypeNotSupportedException('x'),
        isA<HttpException>(),
      );
    });

    test('is thrown and caught', () {
      expect(
        () => throw HttpMediaTypeNotSupportedException('unsupported media'),
        throwsA(isA<HttpMediaTypeNotSupportedException>()),
      );
    });
  });

  group('MultipartException', () {
    test('has default status code 500', () {
      expect(MultipartException('multipart error').statusCode, 500);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/upload');
      final original = Exception('parse failed');
      final st = StackTrace.current;
      final details = {'parts': 3};

      final e = MultipartException(
        'multipart failed',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'multipart failed');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(MultipartException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw MultipartException('multipart error'),
        throwsA(isA<MultipartException>()),
      );
    });
  });

  group('MaxUploadSizeExceededException', () {
    test('has default status code 500', () {
      final e = MaxUploadSizeExceededException(1024, 2048);
      expect(e.statusCode, 500);
    });

    test('stores maxUploadSize and actualSize', () {
      final e = MaxUploadSizeExceededException(1024, 2048);
      expect(e.maxUploadSize, 1024);
      expect(e.actualSize, 2048);
    });

    test('generates correct message', () {
      final e = MaxUploadSizeExceededException(100, 200);
      expect(e.message, contains('100'));
      expect(e.message, contains('200'));
      expect(e.message, contains('exceeded'));
    });

    test('is a MultipartException', () {
      expect(
        MaxUploadSizeExceededException(1, 2),
        isA<MultipartException>(),
      );
    });

    test('is a HttpException', () {
      expect(
        MaxUploadSizeExceededException(1, 2),
        isA<HttpException>(),
      );
    });

    test('constructs with optional parameters', () {
      final uri = Uri.parse('/upload');
      final original = Exception('too big');
      final st = StackTrace.current;
      final details = {'limit': '10MB'};

      final e = MaxUploadSizeExceededException(
        1024,
        2048,
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is thrown and caught', () {
      expect(
        () => throw MaxUploadSizeExceededException(1024, 2048),
        throwsA(isA<MaxUploadSizeExceededException>()),
      );
    });

    test('is caught when catching MultipartException', () {
      bool caught = false;
      try {
        throw MaxUploadSizeExceededException(1024, 2048);
      } on MultipartException {
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('MaxUploadSizePerFileExceededException', () {
    test('has default status code 500', () {
      final e = MaxUploadSizePerFileExceededException(1024, 2048, 'file.txt');
      expect(e.statusCode, 500);
    });

    test('stores maxUploadSizePerFile, actualSize, and fileName', () {
      final e = MaxUploadSizePerFileExceededException(1024, 2048, 'image.png');
      expect(e.maxUploadSizePerFile, 1024);
      expect(e.actualSize, 2048);
      expect(e.fileName, 'image.png');
    });

    test('generates correct message', () {
      final e = MaxUploadSizePerFileExceededException(100, 200, 'test.pdf');
      expect(e.message, contains('100'));
      expect(e.message, contains('200'));
      expect(e.message, contains('test.pdf'));
      expect(e.message, contains('exceeded'));
    });

    test('is a MultipartException', () {
      expect(
        MaxUploadSizePerFileExceededException(1, 2, 'f.txt'),
        isA<MultipartException>(),
      );
    });

    test('is a HttpException', () {
      expect(
        MaxUploadSizePerFileExceededException(1, 2, 'f.txt'),
        isA<HttpException>(),
      );
    });

    test('constructs with optional parameters', () {
      final uri = Uri.parse('/upload');
      final original = Exception('file too large');
      final st = StackTrace.current;
      final details = {'file': 'image.png'};

      final e = MaxUploadSizePerFileExceededException(
        1024,
        2048,
        'image.png',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is thrown and caught', () {
      expect(
        () => throw MaxUploadSizePerFileExceededException(1024, 2048, 'f.txt'),
        throwsA(isA<MaxUploadSizePerFileExceededException>()),
      );
    });

    test('is caught when catching MultipartException', () {
      bool caught = false;
      try {
        throw MaxUploadSizePerFileExceededException(1024, 2048, 'f.txt');
      } on MultipartException {
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('MultipartParseException', () {
    test('has default status code 500', () {
      expect(MultipartParseException('parse error').statusCode, 500);
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/upload');
      final original = FormatException('bad boundary');
      final st = StackTrace.current;
      final details = {'boundary': '----'};

      final e = MultipartParseException(
        'could not parse',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'could not parse');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(MultipartParseException('x'), isA<HttpException>());
    });

    test('is thrown and caught', () {
      expect(
        () => throw MultipartParseException('parse error'),
        throwsA(isA<MultipartParseException>()),
      );
    });
  });

  group('ResponseAlreadyCommittedException', () {
    test('has default status code 500', () {
      expect(
        ResponseAlreadyCommittedException('committed').statusCode,
        500,
      );
    });

    test('constructs with all parameters', () {
      final uri = Uri.parse('/api/response');
      final original = Exception('already sent');
      final st = StackTrace.current;
      final details = {'state': 'committed'};

      final e = ResponseAlreadyCommittedException(
        'response committed',
        uri: uri,
        details: details,
        originalException: original,
        originalStackTrace: st,
      );

      expect(e.message, 'response committed');
      expect(e.uri, uri);
      expect(e.details, details);
      expect(e.originalException, original);
      expect(e.originalStackTrace, st);
    });

    test('is a HttpException', () {
      expect(
        ResponseAlreadyCommittedException('x'),
        isA<HttpException>(),
      );
    });

    test('is thrown and caught', () {
      expect(
        () => throw ResponseAlreadyCommittedException('already committed'),
        throwsA(isA<ResponseAlreadyCommittedException>()),
      );
    });
  });

  group('InvalidPathPatternException', () {
    test('constructs with message and pattern', () {
      final e = InvalidPathPatternException('unclosed bracket', '/api/{id');
      expect(e.pattern, '/api/{id');
    });

    test('constructs with position', () {
      final e = InvalidPathPatternException('bad char', '/api/{id', 9);
      expect(e.pattern, '/api/{id');
      expect(e.position, 9);
    });

    test('constructs without position', () {
      final e = InvalidPathPatternException('bad pattern', '/api/{id');
      expect(e.position, isNull);
    });

    test('toString includes pattern and message', () {
      final e = InvalidPathPatternException('unclosed', '/api/{id');
      final str = e.toString();
      expect(str, contains('InvalidPathPatternException'));
      expect(str, contains('unclosed'));
      expect(str, contains('/api/{id'));
    });

    test('toString includes position when set', () {
      final e = InvalidPathPatternException('bad', '/api/{id', 9);
      final str = e.toString();
      expect(str, contains('Position: 9'));
    });

    test('toString omits position when null', () {
      final e = InvalidPathPatternException('bad', '/api/{id');
      final str = e.toString();
      expect(str, isNot(contains('Position:')));
    });

    test('is a RuntimeException', () {
      expect(
        InvalidPathPatternException('x', 'y'),
        isA<RuntimeException>(),
      );
    });

    test('is NOT a HttpException', () {
      expect(
        InvalidPathPatternException('x', 'y'),
        isNot(isA<HttpException>()),
      );
    });

    test('is thrown and caught', () {
      expect(
        () => throw InvalidPathPatternException('bad', '/api/{id'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('is caught when catching RuntimeException', () {
      bool caught = false;
      try {
        throw InvalidPathPatternException('bad', '/api/{id');
      } on RuntimeException {
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('PathMatchingException', () {
    test('constructs with message, path, and pattern', () {
      final e = PathMatchingException(
        'no match',
        path: '/users/42',
        pattern: '/api/users/{id}',
      );
      expect(e.path, '/users/42');
      expect(e.pattern, '/api/users/{id}');
    });

    test('toString includes all fields', () {
      final e = PathMatchingException(
        'mismatch',
        path: '/users/42',
        pattern: '/api/users/{id}',
      );
      final str = e.toString();
      expect(str, contains('PathMatchingException'));
      expect(str, contains('mismatch'));
      expect(str, contains('/users/42'));
      expect(str, contains('/api/users/{id}'));
    });

    test('is a RuntimeException', () {
      expect(
        PathMatchingException('x', path: 'a', pattern: 'b'),
        isA<RuntimeException>(),
      );
    });

    test('is NOT a HttpException', () {
      expect(
        PathMatchingException('x', path: 'a', pattern: 'b'),
        isNot(isA<HttpException>()),
      );
    });

    test('is thrown and caught', () {
      expect(
        () => throw PathMatchingException(
          'no match',
          path: '/users',
          pattern: '/api/{id}',
        ),
        throwsA(isA<PathMatchingException>()),
      );
    });

    test('is caught when catching RuntimeException', () {
      bool caught = false;
      try {
        throw PathMatchingException(
          'fail',
          path: '/x',
          pattern: '/y',
        );
      } on RuntimeException {
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('WebServerException', () {
    test('constructs with message only', () {
      final e = WebServerException('server crashed');
      expect(e.message, 'server crashed');
    });

    test('constructs with cause', () {
      final cause = Exception('root cause');
      final e = WebServerException('failed', cause: cause);
      expect(e.cause, cause);
    });

    test('constructs with stackTrace', () {
      final st = StackTrace.current;
      final e = WebServerException('failed', stackTrace: st);
      expect(e.stackTrace, st);
    });

    test('constructs with cause and stackTrace', () {
      final cause = FormatException('bad');
      final st = StackTrace.current;
      final e = WebServerException('fail', cause: cause, stackTrace: st);
      expect(e.cause, cause);
      expect(e.stackTrace, st);
    });

    test('is a RuntimeException', () {
      expect(WebServerException('x'), isA<RuntimeException>());
    });

    test('is NOT a HttpException', () {
      expect(WebServerException('x'), isNot(isA<HttpException>()));
    });

    test('is thrown and caught', () {
      expect(
        () => throw WebServerException('server error'),
        throwsA(isA<WebServerException>()),
      );
    });

    test('is caught when catching RuntimeException', () {
      bool caught = false;
      try {
        throw WebServerException('server error');
      } on RuntimeException {
        caught = true;
      }
      expect(caught, isTrue);
    });

    test('toString contains message', () {
      final e = WebServerException('dispatch failed');
      expect(e.toString(), contains('dispatch failed'));
    });
  });

  group('Inheritance hierarchy', () {
    test('all HTTP exceptions extend HttpException', () {
      final exceptions = <HttpException>[
        NotFoundException('x', statusCode: 404),
        BadRequestException('x', statusCode: 400),
        UnauthorizedException('x', statusCode: 401),
        ForbiddenException('x', statusCode: 403),
        MethodNotAllowedException('x', statusCode: 405),
        ConflictException('x', statusCode: 409),
        InternalServerErrorException('x', statusCode: 500),
        ServiceUnavailableException(statusCode: 503),
        PayloadTooLargeException('x', statusCode: 413),
        RequestTimeoutException('x', statusCode: 408),
        TooManyRequestsException('x', statusCode: 429),
        PathVariableException('x', statusCode: 400),
        GatewayTimeoutException('x', statusCode: 504),
        BadGatewayException('x', statusCode: 502),
        UnsupportedMediaTypeException('x', statusCode: 415),
        NotAcceptableException('x', statusCode: 406),
        ViewResolutionException('x'),
        HttpMessageNotReadableException('x'),
        HttpMessageNotWritableException('x'),
        HttpMediaTypeNotSupportedException('x'),
        MultipartException('x'),
        MaxUploadSizeExceededException(1, 2),
        MaxUploadSizePerFileExceededException(1, 2, 'f'),
        MultipartParseException('x'),
        ResponseAlreadyCommittedException('x'),
      ];

      for (final e in exceptions) {
        expect(e, isA<HttpException>(), reason: '${e.runtimeType} should be HttpException');
      }
    });

    test('multipart exceptions form correct sub-hierarchy', () {
      expect(MaxUploadSizeExceededException(1, 2), isA<MultipartException>());
      expect(MaxUploadSizePerFileExceededException(1, 2, 'f'), isA<MultipartException>());
      expect(MultipartException('x'), isA<HttpException>());
    });

    test('path exceptions extend RuntimeException but not HttpException', () {
      final invalid = InvalidPathPatternException('x', 'y');
      final matching = PathMatchingException('x', path: 'a', pattern: 'b');

      expect(invalid, isA<RuntimeException>());
      expect(invalid, isNot(isA<HttpException>()));

      expect(matching, isA<RuntimeException>());
      expect(matching, isNot(isA<HttpException>()));
    });

    test('WebServerException extends RuntimeException but not HttpException', () {
      final e = WebServerException('x');
      expect(e, isA<RuntimeException>());
      expect(e, isNot(isA<HttpException>()));
    });
  });

  group('Exception polymorphism', () {
    test('each exception type can be caught individually', () {
      final exceptions = <Function()>[
        () => throw NotFoundException('x'),
        () => throw BadRequestException('x'),
        () => throw UnauthorizedException('x'),
        () => throw ForbiddenException('x'),
        () => throw MethodNotAllowedException('x'),
        () => throw ConflictException('x'),
        () => throw InternalServerErrorException('x'),
        () => throw ServiceUnavailableException(),
        () => throw PayloadTooLargeException('x'),
        () => throw RequestTimeoutException('x'),
        () => throw TooManyRequestsException('x'),
        () => throw PathVariableException('x'),
        () => throw GatewayTimeoutException('x'),
        () => throw BadGatewayException('x'),
        () => throw UnsupportedMediaTypeException('x'),
        () => throw NotAcceptableException('x'),
        () => throw ViewResolutionException('x'),
        () => throw HttpMessageNotReadableException('x'),
        () => throw HttpMessageNotWritableException('x'),
        () => throw HttpMediaTypeNotSupportedException('x'),
        () => throw MultipartException('x'),
        () => throw MaxUploadSizeExceededException(1, 2),
        () => throw MaxUploadSizePerFileExceededException(1, 2, 'f'),
        () => throw MultipartParseException('x'),
        () => throw ResponseAlreadyCommittedException('x'),
      ];

      for (final throwFn in exceptions) {
        expect(throwFn, throwsA(isA<HttpException>()));
      }
    });

    test('path and server exceptions can be caught as RuntimeException', () {
      expect(
        () => throw InvalidPathPatternException('x', 'y'),
        throwsA(isA<RuntimeException>()),
      );
      expect(
        () => throw PathMatchingException('x', path: 'a', pattern: 'b'),
        throwsA(isA<RuntimeException>()),
      );
      expect(
        () => throw WebServerException('x'),
        throwsA(isA<RuntimeException>()),
      );
    });
  });

  group('Edge cases', () {
    test('empty message is preserved', () {
      final e = HttpException('', statusCode: 400);
      expect(e.message, '');
    });

    test('null uri is handled in toString', () {
      final e = HttpException('msg', statusCode: 400);
      expect(e.toString(), isNot(contains('null')));
    });

    test('empty details map is omitted in toString', () {
      final e = HttpException('msg', statusCode: 400, details: {});
      expect(e.toString(), isNot(contains('Details:')));
    });

    test('toJson handles empty details map', () {
      final e = HttpException('msg', statusCode: 400, details: {});
      final json = e.toJson();
      expect(json.containsKey('details'), isTrue);
    });

    test('toMap handles null uri', () {
      final e = HttpException('msg', statusCode: 400);
      final map = e.toMap();
      expect(map['uri'], isNull);
    });

    test('toMap handles null details', () {
      final e = HttpException('msg', statusCode: 400);
      final map = e.toMap();
      expect(map['details'], isNull);
    });

    test('original exception with non-Throwable type in toJson', () {
      final original = Exception('plain');
      final e = HttpException('msg', statusCode: 400, originalException: original);
      final json = e.toJson();
      expect(json.containsKey('original_exception'), isTrue);
    });

    test('ServiceUnavailableException with empty details map', () {
      final e = ServiceUnavailableException(details: {});
      expect(e.message, 'Unable to start web server');
    });

    test('ServiceUnavailableException with details containing empty strings', () {
      final e = ServiceUnavailableException(
        details: {'key': ''},
      );
      expect(e.message, contains('Unable to start web server'));
    });

    test('ServiceUnavailableException with details containing only non-string values', () {
      final e = ServiceUnavailableException(
        details: {'count': 42},
      );
      expect(e.message, contains('1 error detail(s)'));
    });

    test('ServiceUnavailableException with Throwable original exception', () {
      final original = WebServerException('server crashed');
      final e = ServiceUnavailableException(originalException: original);
      expect(e.message, contains('server crashed'));
    });
  });

  group('Json serialization round-trip consistency', () {
    test('toJson produces consistent keys', () {
      final uri = Uri.parse('https://test.com');
      final e = HttpException(
        'msg',
        uri: uri,
        statusCode: 422,
        details: {'x': 1},
        originalException: FormatException('bad'),
      );

      final json = e.toJson();
      expect(json.keys, containsAll(['uri', 'status_code', 'details', 'original_exception']));
    });

    test('toMap produces consistent keys', () {
      final uri = Uri.parse('https://test.com');
      final e = HttpException(
        'msg',
        uri: uri,
        statusCode: 422,
        details: {'x': 1},
      );

      final map = e.toMap();
      expect(map.keys, containsAll(['type', 'message', 'uri', 'statusCode', 'details']));
    });
  });

  group('Status code defaults', () {
    test('each exception type has the correct default status code', () {
      expect(NotFoundException('x').statusCode, 404);
      expect(BadRequestException('x').statusCode, 400);
      expect(UnauthorizedException('x').statusCode, 401);
      expect(ForbiddenException('x').statusCode, 403);
      expect(MethodNotAllowedException('x').statusCode, 405);
      expect(ConflictException('x').statusCode, 409);
      expect(InternalServerErrorException('x').statusCode, 500);
      expect(ServiceUnavailableException().statusCode, 503);
      expect(PayloadTooLargeException('x').statusCode, 413);
      expect(RequestTimeoutException('x').statusCode, 408);
      expect(TooManyRequestsException('x').statusCode, 429);
      expect(PathVariableException('x').statusCode, 400);
      expect(GatewayTimeoutException('x').statusCode, 504);
      expect(BadGatewayException('x').statusCode, 502);
      expect(UnsupportedMediaTypeException('x').statusCode, 415);
      expect(NotAcceptableException('x').statusCode, 406);
      expect(ViewResolutionException('x').statusCode, 500);
      expect(HttpMessageNotReadableException('x').statusCode, 400);
      expect(HttpMessageNotWritableException('x').statusCode, 500);
      expect(HttpMediaTypeNotSupportedException('x').statusCode, 500);
      expect(MultipartException('x').statusCode, 500);
      expect(MaxUploadSizeExceededException(1, 2).statusCode, 500);
      expect(MaxUploadSizePerFileExceededException(1, 2, 'f').statusCode, 500);
      expect(MultipartParseException('x').statusCode, 500);
      expect(ResponseAlreadyCommittedException('x').statusCode, 500);
    });
  });
}
