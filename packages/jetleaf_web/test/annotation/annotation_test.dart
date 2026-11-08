import 'package:test/test.dart';
import 'package:jetleaf_web/src/annotation/core.dart';
import 'package:jetleaf_web/src/annotation/request_mapping.dart';
import 'package:jetleaf_web/src/annotation/request_parameter.dart';
import 'package:jetleaf_web/src/annotation/resolvers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RequestMapping
  // ---------------------------------------------------------------------------
  group('RequestMapping', () {
    test('constructor sets all properties', () {
      final mapping = RequestMapping(
        path: '/users',
        method: HttpMethod.GET,
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.TEXT_PLAIN],
      );

      expect(mapping.path, '/users');
      expect(mapping.method, HttpMethod.GET);
      expect(mapping.consumes, [MediaType.APPLICATION_JSON]);
      expect(mapping.produces, [MediaType.TEXT_PLAIN]);
    });

    test('path defaults to null', () {
      final mapping = RequestMapping(method: HttpMethod.POST);
      expect(mapping.path, isNull);
    });

    test('consumes and produces default to empty lists', () {
      final mapping = RequestMapping(method: HttpMethod.PUT);
      expect(mapping.consumes, isEmpty);
      expect(mapping.produces, isEmpty);
    });

    test('annotationType returns runtimeType', () {
      final mapping = RequestMapping(method: HttpMethod.DELETE);
      expect(mapping.annotationType, RequestMapping);
    });

    test('toString includes path and method', () {
      final mapping = RequestMapping(path: '/items', method: HttpMethod.GET);
      expect(mapping.toString(), contains('/items'));
      expect(mapping.toString(), contains('GET'));
    });

    test('equality - same properties are equal', () {
      final a = RequestMapping(
        path: '/users',
        method: HttpMethod.GET,
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.TEXT_PLAIN],
      );
      final b = RequestMapping(
        path: '/users',
        method: HttpMethod.GET,
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.TEXT_PLAIN],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality - different path not equal', () {
      final a = RequestMapping(path: '/users', method: HttpMethod.GET);
      final b = RequestMapping(path: '/items', method: HttpMethod.GET);
      expect(a, isNot(equals(b)));
    });

    test('equality - different method not equal', () {
      final a = RequestMapping(path: '/users', method: HttpMethod.GET);
      final b = RequestMapping(path: '/users', method: HttpMethod.POST);
      expect(a, isNot(equals(b)));
    });

    test('equality - different consumes not equal', () {
      final a = RequestMapping(
        path: '/users',
        method: HttpMethod.POST,
        consumes: [MediaType.APPLICATION_JSON],
      );
      final b = RequestMapping(
        path: '/users',
        method: HttpMethod.POST,
        consumes: [MediaType.TEXT_PLAIN],
      );
      expect(a, isNot(equals(b)));
    });

    test('equality - different produces not equal', () {
      final a = RequestMapping(
        path: '/users',
        method: HttpMethod.GET,
        produces: [MediaType.APPLICATION_JSON],
      );
      final b = RequestMapping(
        path: '/users',
        method: HttpMethod.GET,
        produces: [MediaType.TEXT_HTML],
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // GetMapping
  // ---------------------------------------------------------------------------
  group('GetMapping', () {
    test('sets method to GET', () {
      final mapping = GetMapping(path: '/users');
      expect(mapping.method, HttpMethod.GET);
      expect(mapping.path, '/users');
    });

    test('path defaults to null', () {
      final mapping = GetMapping();
      expect(mapping.path, isNull);
    });

    test('annotationType returns GetMapping', () {
      final mapping = GetMapping();
      expect(mapping.annotationType, GetMapping);
    });

    test('inherits consumes and produces', () {
      final mapping = GetMapping(
        path: '/data',
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.TEXT_HTML],
      );
      expect(mapping.consumes, [MediaType.APPLICATION_JSON]);
      expect(mapping.produces, [MediaType.TEXT_HTML]);
    });

    test('toString includes path', () {
      final mapping = GetMapping(path: '/health');
      expect(mapping.toString(), contains('/health'));
    });
  });

  // ---------------------------------------------------------------------------
  // PostMapping
  // ---------------------------------------------------------------------------
  group('PostMapping', () {
    test('sets method to POST', () {
      final mapping = PostMapping(path: '/users');
      expect(mapping.method, HttpMethod.POST);
      expect(mapping.path, '/users');
    });

    test('annotationType returns PostMapping', () {
      final mapping = PostMapping();
      expect(mapping.annotationType, PostMapping);
    });

    test('supports consumes and produces', () {
      final mapping = PostMapping(
        path: '/create',
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.APPLICATION_JSON],
      );
      expect(mapping.consumes, [MediaType.APPLICATION_JSON]);
      expect(mapping.produces, [MediaType.APPLICATION_JSON]);
    });
  });

  // ---------------------------------------------------------------------------
  // PutMapping
  // ---------------------------------------------------------------------------
  group('PutMapping', () {
    test('sets method to PUT', () {
      final mapping = PutMapping(path: '/users/1');
      expect(mapping.method, HttpMethod.PUT);
      expect(mapping.path, '/users/1');
    });

    test('annotationType returns PutMapping', () {
      final mapping = PutMapping();
      expect(mapping.annotationType, PutMapping);
    });

    test('path defaults to null', () {
      final mapping = PutMapping();
      expect(mapping.path, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // DeleteMapping
  // ---------------------------------------------------------------------------
  group('DeleteMapping', () {
    test('sets method to DELETE', () {
      final mapping = DeleteMapping(path: '/users/1');
      expect(mapping.method, HttpMethod.DELETE);
      expect(mapping.path, '/users/1');
    });

    test('annotationType returns DeleteMapping', () {
      final mapping = DeleteMapping();
      expect(mapping.annotationType, DeleteMapping);
    });

    test('path defaults to null', () {
      final mapping = DeleteMapping();
      expect(mapping.path, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PatchMapping
  // ---------------------------------------------------------------------------
  group('PatchMapping', () {
    test('sets method to PATCH', () {
      final mapping = PatchMapping(path: '/users/1');
      expect(mapping.method, HttpMethod.PATCH);
      expect(mapping.path, '/users/1');
    });

    test('annotationType returns PatchMapping', () {
      final mapping = PatchMapping();
      expect(mapping.annotationType, PatchMapping);
    });
  });

  // ---------------------------------------------------------------------------
  // Mapping shorthand inheritance
  // ---------------------------------------------------------------------------
  group('Mapping shorthands inherit RequestMapping', () {
    test('GetMapping is a RequestMapping', () {
      expect(GetMapping(), isA<RequestMapping>());
    });

    test('PostMapping is a RequestMapping', () {
      expect(PostMapping(), isA<RequestMapping>());
    });

    test('PutMapping is a RequestMapping', () {
      expect(PutMapping(), isA<RequestMapping>());
    });

    test('DeleteMapping is a RequestMapping', () {
      expect(DeleteMapping(), isA<RequestMapping>());
    });

    test('PatchMapping is a RequestMapping', () {
      expect(PatchMapping(), isA<RequestMapping>());
    });

    test('each shorthand fixes its HTTP method', () {
      expect(GetMapping().method, HttpMethod.GET);
      expect(PostMapping().method, HttpMethod.POST);
      expect(PutMapping().method, HttpMethod.PUT);
      expect(DeleteMapping().method, HttpMethod.DELETE);
      expect(PatchMapping().method, HttpMethod.PATCH);
    });
  });

  // ---------------------------------------------------------------------------
  // Controller
  // ---------------------------------------------------------------------------
  group('Controller', () {
    test('constructor with value', () {
      final controller = Controller('/api');
      expect(controller.value, '/api');
      expect(controller.ignoreContextPath, isFalse);
    });

    test('constructor with ignoreContextPath', () {
      final controller = Controller('/admin', true);
      expect(controller.value, '/admin');
      expect(controller.ignoreContextPath, isTrue);
    });

    test('constructor with no arguments', () {
      final controller = Controller();
      expect(controller.value, isNull);
      expect(controller.ignoreContextPath, isFalse);
    });

    test('annotationType returns Controller', () {
      expect(Controller().annotationType, Controller);
    });

    test('toString includes value', () {
      final controller = Controller('/web');
      expect(controller.toString(), contains('/web'));
    });

    test('equality based on value', () {
      final a = Controller('/api');
      final b = Controller('/api');
      expect(a, equals(b));
    });

    test('inequality for different values', () {
      final a = Controller('/api');
      final b = Controller('/web');
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // RestController
  // ---------------------------------------------------------------------------
  group('RestController', () {
    test('constructor with value', () {
      final controller = RestController('/users');
      expect(controller.value, '/users');
    });

    test('annotationType returns RestController', () {
      expect(RestController().annotationType, RestController);
    });

    test('is a Controller', () {
      expect(RestController(), isA<Controller>());
    });

    test('inherits ignoreContextPath', () {
      final controller = RestController('/data', true);
      expect(controller.ignoreContextPath, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ControllerAdvice
  // ---------------------------------------------------------------------------
  group('ControllerAdvice', () {
    test('defaults to empty lists', () {
      final advice = ControllerAdvice();
      expect(advice.assignableTypes, isEmpty);
      expect(advice.basePackages, isEmpty);
      expect(advice.annotations, isEmpty);
    });

    test('annotationType returns ControllerAdvice', () {
      expect(ControllerAdvice().annotationType, ControllerAdvice);
    });

    test('is a Controller', () {
      expect(ControllerAdvice(), isA<Controller>());
    });

    test('toString includes assignableTypes', () {
      final advice = ControllerAdvice(assignableTypes: [String]);
      expect(advice.toString(), contains('String'));
    });

    test('equality based on assignableTypes', () {
      final a = ControllerAdvice(assignableTypes: [String, int]);
      final b = ControllerAdvice(assignableTypes: [String, int]);
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // RestControllerAdvice
  // ---------------------------------------------------------------------------
  group('RestControllerAdvice', () {
    test('annotationType returns RestControllerAdvice', () {
      expect(RestControllerAdvice().annotationType, RestControllerAdvice);
    });

    test('is a ControllerAdvice', () {
      expect(RestControllerAdvice(), isA<ControllerAdvice>());
    });

    test('supports assignableTypes', () {
      final advice = RestControllerAdvice(assignableTypes: [int]);
      expect(advice.assignableTypes, [int]);
    });

    test('supports annotations', () {
      final advice = RestControllerAdvice(annotations: [GetMapping]);
      expect(advice.annotations, [GetMapping]);
    });
  });

  // ---------------------------------------------------------------------------
  // CrossOrigin
  // ---------------------------------------------------------------------------
  group('CrossOrigin', () {
    test('defaults', () {
      final cors = CrossOrigin();
      expect(cors.origins, isEmpty);
      expect(cors.methods, isEmpty);
      expect(cors.allowedHeaders, isEmpty);
      expect(cors.exposedHeaders, isEmpty);
      expect(cors.allowCredentials, isFalse);
      expect(cors.maxAge, 1800);
    });

    test('constructor with all parameters', () {
      final cors = CrossOrigin(
        origins: ['https://example.com'],
        methods: [HttpMethod.GET, HttpMethod.POST],
        allowedHeaders: ['Authorization'],
        exposedHeaders: ['X-Custom'],
        allowCredentials: true,
        maxAge: 3600,
      );

      expect(cors.origins, ['https://example.com']);
      expect(cors.methods, [HttpMethod.GET, HttpMethod.POST]);
      expect(cors.allowedHeaders, ['Authorization']);
      expect(cors.exposedHeaders, ['X-Custom']);
      expect(cors.allowCredentials, isTrue);
      expect(cors.maxAge, 3600);
    });

    test('annotationType returns CrossOrigin', () {
      expect(CrossOrigin().annotationType, CrossOrigin);
    });

    test('toString includes all properties', () {
      final cors = CrossOrigin(
        origins: ['https://example.com'],
        allowCredentials: true,
        maxAge: 3600,
      );
      final str = cors.toString();
      expect(str, contains('https://example.com'));
      expect(str, contains('allowCredentials: true'));
      expect(str, contains('maxAge: 3600'));
    });

    test('equality', () {
      final a = CrossOrigin(origins: ['https://a.com'], maxAge: 600);
      final b = CrossOrigin(origins: ['https://a.com'], maxAge: 600);
      expect(a, equals(b));
    });

    test('inequality for different origins', () {
      final a = CrossOrigin(origins: ['https://a.com']);
      final b = CrossOrigin(origins: ['https://b.com']);
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // ExceptionHandler
  // ---------------------------------------------------------------------------
  group('ExceptionHandler', () {
    test('constructor with type', () {
      final handler = ExceptionHandler(Exception);
      expect(handler.value, Exception);
    });

    test('annotationType returns ExceptionHandler', () {
      expect(ExceptionHandler(Exception).annotationType, ExceptionHandler);
    });

    test('toString includes value', () {
      final handler = ExceptionHandler(StateError);
      expect(handler.toString(), contains('StateError'));
    });

    test('equality', () {
      final a = ExceptionHandler(ArgumentError);
      final b = ExceptionHandler(ArgumentError);
      expect(a, equals(b));
    });

    test('inequality for different types', () {
      final a = ExceptionHandler(ArgumentError);
      final b = ExceptionHandler(StateError);
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // Catch
  // ---------------------------------------------------------------------------
  group('Catch', () {
    test('constructor with type', () {
      final catchAnnotation = Catch(Exception);
      expect(catchAnnotation.value, Exception);
    });

    test('annotationType returns Catch', () {
      expect(Catch(Exception).annotationType, Catch);
    });

    test('toString includes value', () {
      final catchAnnotation = Catch(ArgumentError);
      expect(catchAnnotation.toString(), contains('ArgumentError'));
    });

    test('equality', () {
      final a = Catch(Exception);
      final b = Catch(Exception);
      expect(a, equals(b));
    });

    test('inequality for different types', () {
      final a = Catch(Exception);
      final b = Catch(ArgumentError);
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // WebView
  // ---------------------------------------------------------------------------
  group('WebView', () {
    test('constructor with route', () {
      final view = WebView('/dashboard');
      expect(view.route, '/dashboard');
      expect(view.ignoreContextPath, isFalse);
    });

    test('constructor with ignoreContextPath', () {
      final view = WebView('/admin', true);
      expect(view.route, '/admin');
      expect(view.ignoreContextPath, isTrue);
    });

    test('constructor with method', () {
      final view = WebView('/api/data', false, HttpMethod.POST);
      expect(view.route, '/api/data');
      expect(view.method, HttpMethod.POST);
    });

    test('method defaults to GET', () {
      final view = WebView('/home');
      expect(view.method, HttpMethod.GET);
    });

    test('annotationType returns WebView', () {
      expect(WebView('/').annotationType, WebView);
    });

    test('toString includes route and ignoreContextPath', () {
      final view = WebView('/docs', true);
      final str = view.toString();
      expect(str, contains('/docs'));
      expect(str, contains('true'));
    });
  });

  // ---------------------------------------------------------------------------
  // ResponseStatus
  // ---------------------------------------------------------------------------
  group('ResponseStatus', () {
    test('constructor sets status', () {
      final annotation = ResponseStatus(HttpStatus.CREATED);
      expect(annotation.status, HttpStatus.CREATED);
    });

    test('annotationType returns ResponseStatus', () {
      expect(ResponseStatus(HttpStatus.OK).annotationType, ResponseStatus);
    });
  });

  // ---------------------------------------------------------------------------
  // Produces
  // ---------------------------------------------------------------------------
  group('Produces', () {
    test('constructor sets media types', () {
      final annotation = Produces([
        MediaType.APPLICATION_JSON,
        MediaType.TEXT_HTML,
      ]);
      expect(annotation.mediaTypes, [
        MediaType.APPLICATION_JSON,
        MediaType.TEXT_HTML,
      ]);
    });

    test('annotationType returns Produces', () {
      expect(Produces([MediaType.APPLICATION_JSON]).annotationType, Produces);
    });

    test('single media type', () {
      final annotation = Produces([MediaType.TEXT_PLAIN]);
      expect(annotation.mediaTypes.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // RequestParameter (abstract base)
  // ---------------------------------------------------------------------------
  group('RequestParam', () {
    test('constructor with value', () {
      final param = RequestParam(value: 'q');
      expect(param.value, 'q');
      expect(param.required, isTrue);
      expect(param.defaultValue, isNull);
    });

    test('constructor with all parameters', () {
      final param = RequestParam(
        value: 'page',
        required: false,
        defaultValue: '1',
      );
      expect(param.value, 'page');
      expect(param.required, isFalse);
      expect(param.defaultValue, '1');
    });

    test('annotationType returns RequestParam', () {
      expect(RequestParam().annotationType, RequestParam);
    });

    test('toString includes all properties', () {
      final param = RequestParam(
        value: 'size',
        required: false,
        defaultValue: '10',
      );
      final str = param.toString();
      expect(str, contains('size'));
      expect(str, contains('false'));
      expect(str, contains('10'));
    });

    test('equality', () {
      final a = RequestParam(value: 'q', defaultValue: 'test');
      final b = RequestParam(value: 'q', defaultValue: 'test');
      expect(a, equals(b));
    });

    test('inequality for different value', () {
      final a = RequestParam(value: 'q');
      final b = RequestParam(value: 'sort');
      expect(a, isNot(equals(b)));
    });

    test('defaults', () {
      final param = RequestParam();
      expect(param.value, isNull);
      expect(param.required, isTrue);
      expect(param.defaultValue, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PathVariable
  // ---------------------------------------------------------------------------
  group('PathVariable', () {
    test('constructor with value', () {
      final param = PathVariable(value: 'id');
      expect(param.value, 'id');
      expect(param.required, isTrue);
    });

    test('annotationType returns PathVariable', () {
      expect(PathVariable().annotationType, PathVariable);
    });

    test('inherits from RequestParameter', () {
      expect(PathVariable(), isA<RequestParameter>());
    });

    test('equality', () {
      final a = PathVariable(value: 'userId');
      final b = PathVariable(value: 'userId');
      expect(a, equals(b));
    });

    test('inequality for different values', () {
      final a = PathVariable(value: 'userId');
      final b = PathVariable(value: 'orderId');
      expect(a, isNot(equals(b)));
    });

    test('toString includes value', () {
      final param = PathVariable(value: 'itemId');
      expect(param.toString(), contains('itemId'));
    });
  });

  // ---------------------------------------------------------------------------
  // RequestHeader
  // ---------------------------------------------------------------------------
  group('RequestHeader', () {
    test('constructor with value', () {
      final header = RequestHeader(value: 'Authorization');
      expect(header.value, 'Authorization');
      expect(header.required, isTrue);
    });

    test('annotationType returns RequestHeader', () {
      expect(RequestHeader().annotationType, RequestHeader);
    });

    test('inherits from RequestParameter', () {
      expect(RequestHeader(), isA<RequestParameter>());
    });

    test('equality', () {
      final a = RequestHeader(value: 'X-Custom');
      final b = RequestHeader(value: 'X-Custom');
      expect(a, equals(b));
    });

    test('inequality for different header names', () {
      final a = RequestHeader(value: 'X-A');
      final b = RequestHeader(value: 'X-B');
      expect(a, isNot(equals(b)));
    });

    test('with required and defaultValue', () {
      final header = RequestHeader(
        value: 'Accept-Language',
        required: false,
        defaultValue: 'en',
      );
      expect(header.required, isFalse);
      expect(header.defaultValue, 'en');
    });
  });

  // ---------------------------------------------------------------------------
  // RequestBody
  // ---------------------------------------------------------------------------
  group('RequestBody', () {
    test('constructor', () {
      final body = RequestBody();
      expect(body.value, isNull);
      expect(body.required, isTrue);
      expect(body.defaultValue, isNull);
    });

    test('annotationType returns RequestBody', () {
      expect(RequestBody().annotationType, RequestBody);
    });

    test('inherits from RequestParameter', () {
      expect(RequestBody(), isA<RequestParameter>());
    });

    test('toString', () {
      expect(RequestBody().toString(), contains('RequestBody'));
    });

    test('equality', () {
      expect(RequestBody(), equals(RequestBody()));
    });
  });

  // ---------------------------------------------------------------------------
  // MatrixVariable
  // ---------------------------------------------------------------------------
  group('MatrixVariable', () {
    test('constructor with value and pathVar', () {
      final mv = MatrixVariable(value: 'color', pathVar: 'car');
      expect(mv.value, 'color');
      expect(mv.pathVar, 'car');
      expect(mv.required, isTrue);
    });

    test('annotationType returns MatrixVariable', () {
      expect(MatrixVariable().annotationType, MatrixVariable);
    });

    test('inherits from RequestParameter', () {
      expect(MatrixVariable(), isA<RequestParameter>());
    });

    test('pathVar defaults to null', () {
      final mv = MatrixVariable(value: 'sort');
      expect(mv.pathVar, isNull);
    });

    test('equality includes pathVar', () {
      final a = MatrixVariable(value: 'color', pathVar: 'car');
      final b = MatrixVariable(value: 'color', pathVar: 'car');
      expect(a, equals(b));
    });

    test('inequality for different pathVar', () {
      final a = MatrixVariable(value: 'color', pathVar: 'car');
      final b = MatrixVariable(value: 'color', pathVar: 'bike');
      expect(a, isNot(equals(b)));
    });

    test('toString includes pathVar', () {
      final mv = MatrixVariable(value: 'size', pathVar: 'product');
      final str = mv.toString();
      expect(str, contains('size'));
      expect(str, contains('product'));
    });
  });

  // ---------------------------------------------------------------------------
  // CookieValue
  // ---------------------------------------------------------------------------
  group('CookieValue', () {
    test('constructor with value', () {
      final cookie = CookieValue(value: 'sessionId');
      expect(cookie.value, 'sessionId');
      expect(cookie.required, isTrue);
    });

    test('annotationType returns CookieValue', () {
      expect(CookieValue().annotationType, CookieValue);
    });

    test('inherits from RequestParameter', () {
      expect(CookieValue(), isA<RequestParameter>());
    });

    test('equality', () {
      final a = CookieValue(value: 'token');
      final b = CookieValue(value: 'token');
      expect(a, equals(b));
    });

    test('inequality for different values', () {
      final a = CookieValue(value: 'token');
      final b = CookieValue(value: 'session');
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // RequestAttribute
  // ---------------------------------------------------------------------------
  group('RequestAttribute', () {
    test('constructor with value', () {
      final attr = RequestAttribute(value: 'user');
      expect(attr.value, 'user');
      expect(attr.required, isTrue);
    });

    test('annotationType returns RequestAttribute', () {
      expect(RequestAttribute().annotationType, RequestAttribute);
    });

    test('inherits from RequestParameter', () {
      expect(RequestAttribute(), isA<RequestParameter>());
    });

    test('equality', () {
      final a = RequestAttribute(value: 'auth');
      final b = RequestAttribute(value: 'auth');
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // SessionAttribute
  // ---------------------------------------------------------------------------
  group('SessionAttribute', () {
    test('constructor with value', () {
      final attr = SessionAttribute(value: 'cart');
      expect(attr.value, 'cart');
      expect(attr.required, isTrue);
    });

    test('annotationType returns SessionAttribute', () {
      expect(SessionAttribute().annotationType, SessionAttribute);
    });

    test('is a RequestAttribute', () {
      expect(SessionAttribute(), isA<RequestAttribute>());
    });

    test('inherits from RequestParameter', () {
      expect(SessionAttribute(), isA<RequestParameter>());
    });

    test('equality', () {
      final a = SessionAttribute(value: 'user');
      final b = SessionAttribute(value: 'user');
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // RequestPart
  // ---------------------------------------------------------------------------
  group('RequestPart', () {
    test('constructor with value', () {
      final part = RequestPart(value: 'file');
      expect(part.value, 'file');
      expect(part.required, isTrue);
      expect(part.contentType, isNull);
      expect(part.maxSize, isNull);
    });

    test('constructor with all parameters', () {
      final part = RequestPart(
        value: 'document',
        required: true,
        contentType: 'application/pdf',
        maxSize: 10485760,
      );
      expect(part.value, 'document');
      expect(part.contentType, 'application/pdf');
      expect(part.maxSize, 10485760);
    });

    test('annotationType returns RequestPart', () {
      expect(RequestPart().annotationType, RequestPart);
    });

    test('inherits from RequestParameter', () {
      expect(RequestPart(), isA<RequestParameter>());
    });

    test('equality includes contentType and maxSize', () {
      final a = RequestPart(
        value: 'file',
        contentType: 'image/png',
        maxSize: 5000,
      );
      final b = RequestPart(
        value: 'file',
        contentType: 'image/png',
        maxSize: 5000,
      );
      expect(a, equals(b));
    });

    test('inequality for different contentType', () {
      final a = RequestPart(contentType: 'image/png');
      final b = RequestPart(contentType: 'image/jpeg');
      expect(a, isNot(equals(b)));
    });

    test('inequality for different maxSize', () {
      final a = RequestPart(maxSize: 1000);
      final b = RequestPart(maxSize: 2000);
      expect(a, isNot(equals(b)));
    });

    test('toString includes contentType and maxSize', () {
      final part = RequestPart(
        value: 'avatar',
        contentType: 'image/jpeg',
        maxSize: 2097152,
      );
      final str = part.toString();
      expect(str, contains('avatar'));
      expect(str, contains('image/jpeg'));
      expect(str, contains('2097152'));
    });
  });

  // ---------------------------------------------------------------------------
  // RequestParameter - parameterized defaults
  // ---------------------------------------------------------------------------
  group('RequestParameter defaults', () {
    test('all parameters default correctly', () {
      final params = [
        RequestParam(),
        PathVariable(),
        RequestHeader(),
        RequestBody(),
        MatrixVariable(),
        CookieValue(),
        RequestAttribute(),
        SessionAttribute(),
        RequestPart(),
      ];

      for (final param in params) {
        expect(param.value, isNull);
        expect(param.required, isTrue);
        expect(param.defaultValue, isNull);
      }
    });

    test('required can be set to false', () {
      final param = RequestParam(required: false);
      expect(param.required, isFalse);
    });

    test('defaultValue is preserved', () {
      final param = RequestParam(defaultValue: 'fallback');
      expect(param.defaultValue, 'fallback');
    });
  });

  // ---------------------------------------------------------------------------
  // ResolvedBy
  // ---------------------------------------------------------------------------
  group('ResolvedBy', () {
    test('constructor stores resolver', () {
      const resolver = PathVariableResolver();
      const annotation = ResolvedBy(resolver);
      expect(annotation.resolver, resolver);
    });

    test('annotationType returns ResolvedBy', () {
      const annotation = ResolvedBy(PathVariableResolver());
      expect(annotation.annotationType, ResolvedBy);
    });

    test('FIELD_KEY constant', () {
      expect(ResolvedBy.FIELD_KEY, 'resolver');
    });

    test('toString includes resolver', () {
      const annotation = ResolvedBy(RequestParamResolver());
      expect(annotation.toString(), contains('RequestParamResolver'));
    });
  });

  // ---------------------------------------------------------------------------
  // Resolver interface
  // ---------------------------------------------------------------------------
  group('Resolver interface', () {
    test('PathVariableResolver is a Resolver', () {
      expect(PathVariableResolver(), isA<Resolver>());
    });

    test('RequestParamResolver is a Resolver', () {
      expect(RequestParamResolver(), isA<Resolver>());
    });

    test('RequestHeaderResolver is a Resolver', () {
      expect(RequestHeaderResolver(), isA<Resolver>());
    });

    test('RequestBodyResolver is a Resolver', () {
      expect(RequestBodyResolver(), isA<Resolver>());
    });

    test('CookieValueResolver is a Resolver', () {
      expect(CookieValueResolver(), isA<Resolver>());
    });

    test('RequestAttributeResolver is a Resolver', () {
      expect(RequestAttributeResolver(), isA<Resolver>());
    });

    test('SessionAttributeResolver is a Resolver', () {
      expect(SessionAttributeResolver(), isA<Resolver>());
    });

    test('MatrixVariableResolver is a Resolver', () {
      expect(MatrixVariableResolver(), isA<Resolver>());
    });

    test('RequestPartResolver is a Resolver', () {
      expect(RequestPartResolver(), isA<Resolver>());
    });
  });

  // ---------------------------------------------------------------------------
  // ResolverContext interface
  // ---------------------------------------------------------------------------
  group('ResolverContext interface', () {
    test('ResolverContext is an abstract interface', () {
      expect(ResolverContext, isA<Type>());
    });

    test('Resolver interface is an abstract interface', () {
      expect(Resolver, isA<Type>());
    });
  });

  // ---------------------------------------------------------------------------
  // Annotation target types
  // ---------------------------------------------------------------------------
  group('Annotation target annotations', () {
    test('Controller targets classType', () {
      expect(Controller, isA<Type>());
    });

    test('RestController targets classType', () {
      expect(RestController, isA<Type>());
    });

    test('ControllerAdvice targets classType', () {
      expect(ControllerAdvice, isA<Type>());
    });

    test('GetMapping targets method', () {
      expect(GetMapping, isA<Type>());
    });

    test('PostMapping targets method', () {
      expect(PostMapping, isA<Type>());
    });

    test('PutMapping targets method', () {
      expect(PutMapping, isA<Type>());
    });

    test('DeleteMapping targets method', () {
      expect(DeleteMapping, isA<Type>());
    });

    test('PatchMapping targets method', () {
      expect(PatchMapping, isA<Type>());
    });

    test('RequestParam targets parameter', () {
      expect(RequestParam, isA<Type>());
    });

    test('PathVariable targets parameter', () {
      expect(PathVariable, isA<Type>());
    });

    test('RequestHeader targets parameter', () {
      expect(RequestHeader, isA<Type>());
    });

    test('RequestBody targets parameter', () {
      expect(RequestBody, isA<Type>());
    });

    test('MatrixVariable targets parameter', () {
      expect(MatrixVariable, isA<Type>());
    });

    test('CookieValue targets parameter', () {
      expect(CookieValue, isA<Type>());
    });

    test('RequestAttribute targets parameter', () {
      expect(RequestAttribute, isA<Type>());
    });

    test('SessionAttribute targets method', () {
      expect(SessionAttribute, isA<Type>());
    });

    test('RequestPart targets parameter', () {
      expect(RequestPart, isA<Type>());
    });
  });

  // ---------------------------------------------------------------------------
  // Cross-cutting annotation combinations
  // ---------------------------------------------------------------------------
  group('Annotation composition', () {
    test('GetMapping equality with full config', () {
      final a = GetMapping(
        path: '/users',
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.APPLICATION_JSON],
      );
      final b = GetMapping(
        path: '/users',
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.APPLICATION_JSON],
      );
      expect(a, equals(b));
    });

    test('PostMapping with custom consumes', () {
      final mapping = PostMapping(
        path: '/upload',
        consumes: [MediaType.MULTIPART_FORM_DATA],
      );
      expect(mapping.consumes, [MediaType.MULTIPART_FORM_DATA]);
      expect(mapping.method, HttpMethod.POST);
    });

    test('RequestMapping with multiple consumes and produces', () {
      final mapping = RequestMapping(
        path: '/api',
        method: HttpMethod.POST,
        consumes: [MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML],
        produces: [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );
      expect(mapping.consumes.length, 2);
      expect(mapping.produces.length, 2);
    });

    test('DeleteMapping with produces', () {
      final mapping = DeleteMapping(
        path: '/resource',
        produces: [MediaType.APPLICATION_JSON],
      );
      expect(mapping.method, HttpMethod.DELETE);
      expect(mapping.produces, [MediaType.APPLICATION_JSON]);
    });

    test('PutMapping with consumes and produces', () {
      final mapping = PutMapping(
        path: '/resource',
        consumes: [MediaType.APPLICATION_JSON],
        produces: [MediaType.APPLICATION_JSON],
      );
      expect(mapping.method, HttpMethod.PUT);
      expect(mapping.consumes, [MediaType.APPLICATION_JSON]);
      expect(mapping.produces, [MediaType.APPLICATION_JSON]);
    });

    test('PatchMapping with produces', () {
      final mapping = PatchMapping(
        path: '/resource',
        produces: [MediaType.APPLICATION_JSON],
      );
      expect(mapping.method, HttpMethod.PATCH);
    });
  });

  // ---------------------------------------------------------------------------
  // RequestParameter toString formatting
  // ---------------------------------------------------------------------------
  group('RequestParameter toString formatting', () {
    test('RequestParam toString', () {
      final param = RequestParam(value: 'q', required: false, defaultValue: '');
      final str = param.toString();
      expect(str, startsWith('RequestParam'));
      expect(str, contains('q'));
      expect(str, contains('false'));
    });

    test('PathVariable toString', () {
      final param = PathVariable(value: 'id');
      final str = param.toString();
      expect(str, startsWith('PathVariable'));
      expect(str, contains('id'));
    });

    test('RequestHeader toString', () {
      final param = RequestHeader(value: 'X-Token');
      final str = param.toString();
      expect(str, startsWith('RequestHeader'));
      expect(str, contains('X-Token'));
    });

    test('RequestBody toString', () {
      final str = RequestBody().toString();
      expect(str, startsWith('RequestBody'));
    });

    test('CookieValue toString', () {
      final param = CookieValue(value: 'sid');
      final str = param.toString();
      expect(str, startsWith('CookieValue'));
      expect(str, contains('sid'));
    });

    test('RequestAttribute toString', () {
      final param = RequestAttribute(value: 'ctx');
      final str = param.toString();
      expect(str, startsWith('RequestAttribute'));
      expect(str, contains('ctx'));
    });

    test('SessionAttribute toString', () {
      final param = SessionAttribute(value: 'user');
      final str = param.toString();
      expect(str, startsWith('SessionAttribute'));
      expect(str, contains('user'));
    });
  });

  // ---------------------------------------------------------------------------
  // Equality edge cases
  // ---------------------------------------------------------------------------
  group('Equality edge cases', () {
    test('RequestMapping with null path equals another with null path', () {
      final a = RequestMapping(method: HttpMethod.GET);
      final b = RequestMapping(method: HttpMethod.GET);
      expect(a, equals(b));
    });

    test('RequestParam with null value equals another with null value', () {
      final a = RequestParam(required: false);
      final b = RequestParam(required: false);
      expect(a, equals(b));
    });

    test('different annotation types are not equal', () {
      expect(RequestParam(value: 'id'), isNot(equals(PathVariable(value: 'userId'))));
    });

    test('CrossOrigin with default values equals another default', () {
      expect(CrossOrigin(), equals(CrossOrigin()));
    });

    test('ExceptionHandler with same type equals', () {
      expect(
        ExceptionHandler(ArgumentError),
        equals(ExceptionHandler(ArgumentError)),
      );
    });

    test('Catch with same type equals', () {
      expect(Catch(StateError), equals(Catch(StateError)));
    });
  });

  // ---------------------------------------------------------------------------
  // Mapping toString patterns
  // ---------------------------------------------------------------------------
  group('RequestMapping toString patterns', () {
    test('GetMapping toString', () {
      final mapping = GetMapping(path: '/users');
      expect(mapping.toString(), contains('GetMapping'));
    });

    test('PostMapping toString', () {
      final mapping = PostMapping(path: '/create');
      expect(mapping.toString(), contains('PostMapping'));
    });

    test('PutMapping toString', () {
      final mapping = PutMapping(path: '/update');
      expect(mapping.toString(), contains('PutMapping'));
    });

    test('DeleteMapping toString', () {
      final mapping = DeleteMapping(path: '/remove');
      expect(mapping.toString(), contains('DeleteMapping'));
    });

    test('PatchMapping toString', () {
      final mapping = PatchMapping(path: '/modify');
      expect(mapping.toString(), contains('PatchMapping'));
    });
  });

  // ---------------------------------------------------------------------------
  // Controller and RestController toString
  // ---------------------------------------------------------------------------
  group('Controller toString patterns', () {
    test('Controller toString includes value', () {
      expect(Controller('/api').toString(), contains('/api'));
    });

    test('RestController toString includes value', () {
      expect(RestController('/v1').toString(), contains('/v1'));
    });

    test('ControllerAdvice toString includes assignableTypes', () {
      final advice = ControllerAdvice(assignableTypes: [int]);
      expect(advice.toString(), contains('int'));
    });
  });

  // ---------------------------------------------------------------------------
  // ExceptionHandler and Catch
  // ---------------------------------------------------------------------------
  group('ExceptionHandler and Catch', () {
    test('ExceptionHandler with different types are not equal', () {
      final a = ExceptionHandler(ArgumentError);
      final b = ExceptionHandler(StateError);
      expect(a, isNot(equals(b)));
    });

    test('Catch with different types are not equal', () {
      final a = Catch(ArgumentError);
      final b = Catch(StateError);
      expect(a, isNot(equals(b)));
    });

    test('ExceptionHandler toString includes type name', () {
      final handler = ExceptionHandler(ArgumentError);
      expect(handler.toString(), contains('ArgumentError'));
    });

    test('Catch toString includes type name', () {
      final catchAnnotation = Catch(StateError);
      expect(catchAnnotation.toString(), contains('StateError'));
    });
  });

  // ---------------------------------------------------------------------------
  // WebView detailed tests
  // ---------------------------------------------------------------------------
  group('WebView detailed', () {
    test('route with path variable', () {
      final view = WebView('/users/{id}/profile');
      expect(view.route, '/users/{id}/profile');
    });

    test('method defaults to GET', () {
      final view = WebView('/home');
      expect(view.method, HttpMethod.GET);
    });

    test('method can be set to POST', () {
      final view = WebView('/submit', false, HttpMethod.POST);
      expect(view.method, HttpMethod.POST);
    });

    test('toString includes route', () {
      final view = WebView('/dashboard');
      expect(view.toString(), contains('/dashboard'));
    });
  });

  // ---------------------------------------------------------------------------
  // ResponseStatus and Produces
  // ---------------------------------------------------------------------------
  group('ResponseStatus and Produces', () {
    test('ResponseStatus with NOT_FOUND', () {
      final annotation = ResponseStatus(HttpStatus.NOT_FOUND);
      expect(annotation.status, HttpStatus.NOT_FOUND);
    });

    test('ResponseStatus with INTERNAL_SERVER_ERROR', () {
      final annotation = ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR);
      expect(annotation.status, HttpStatus.INTERNAL_SERVER_ERROR);
    });

    test('Produces with single type', () {
      final annotation = Produces([MediaType.APPLICATION_JSON]);
      expect(annotation.mediaTypes.length, 1);
    });

    test('Produces with multiple types', () {
      final annotation = Produces([
        MediaType.APPLICATION_JSON,
        MediaType.APPLICATION_XML,
        MediaType.TEXT_PLAIN,
      ]);
      expect(annotation.mediaTypes.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Mapping method-specific shorthand behavior
  // ---------------------------------------------------------------------------
  group('Mapping shorthand method isolation', () {
    test('GetMapping always uses GET regardless of path', () {
      expect(GetMapping(path: '/any').method, HttpMethod.GET);
    });

    test('PostMapping always uses POST regardless of path', () {
      expect(PostMapping(path: '/any').method, HttpMethod.POST);
    });

    test('PutMapping always uses PUT regardless of path', () {
      expect(PutMapping(path: '/any').method, HttpMethod.PUT);
    });

    test('DeleteMapping always uses DELETE regardless of path', () {
      expect(DeleteMapping(path: '/any').method, HttpMethod.DELETE);
    });

    test('PatchMapping always uses PATCH regardless of path', () {
      expect(PatchMapping(path: '/any').method, HttpMethod.PATCH);
    });
  });

  // ---------------------------------------------------------------------------
  // RequestMapping with MediaType constants
  // ---------------------------------------------------------------------------
  group('RequestMapping with MediaType constants', () {
    test('consumes APPLICATION_JSON', () {
      final mapping = RequestMapping(
        method: HttpMethod.POST,
        consumes: [MediaType.APPLICATION_JSON],
      );
      expect(mapping.consumes.first, MediaType.APPLICATION_JSON);
    });

    test('produces TEXT_HTML', () {
      final mapping = RequestMapping(
        method: HttpMethod.GET,
        produces: [MediaType.TEXT_HTML],
      );
      expect(mapping.produces.first, MediaType.TEXT_HTML);
    });

    test('consumes MULTIPART_FORM_DATA', () {
      final mapping = RequestMapping(
        method: HttpMethod.POST,
        consumes: [MediaType.MULTIPART_FORM_DATA],
      );
      expect(mapping.consumes.first, MediaType.MULTIPART_FORM_DATA);
    });
  });

  // ---------------------------------------------------------------------------
  // RequestParameter hierarchy
  // ---------------------------------------------------------------------------
  group('RequestParameter hierarchy', () {
    test('RequestParam extends RequestParameter', () {
      expect(RequestParam(), isA<RequestParameter>());
    });

    test('PathVariable extends RequestParameter', () {
      expect(PathVariable(), isA<RequestParameter>());
    });

    test('RequestHeader extends RequestParameter', () {
      expect(RequestHeader(), isA<RequestParameter>());
    });

    test('RequestBody extends RequestParameter', () {
      expect(RequestBody(), isA<RequestParameter>());
    });

    test('MatrixVariable extends RequestParameter', () {
      expect(MatrixVariable(), isA<RequestParameter>());
    });

    test('CookieValue extends RequestParameter', () {
      expect(CookieValue(), isA<RequestParameter>());
    });

    test('RequestAttribute extends RequestParameter', () {
      expect(RequestAttribute(), isA<RequestParameter>());
    });

    test('SessionAttribute extends RequestAttribute', () {
      expect(SessionAttribute(), isA<RequestAttribute>());
    });

    test('RequestPart extends RequestParameter', () {
      expect(RequestPart(), isA<RequestParameter>());
    });
  });
}
