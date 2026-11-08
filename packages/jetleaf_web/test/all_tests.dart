import 'package:test/test.dart';

import 'http/http_method_test.dart' as http_method_test;
import 'http/http_status_test.dart' as http_status_test;
import 'http/media_type_test.dart' as media_type_test;
import 'http/http_cookie_test.dart' as http_cookie_test;
import 'http/http_range_test.dart' as http_range_test;
import 'http/etag_test.dart' as etag_test;
import 'http/cache_control_test.dart' as cache_control_test;
import 'http/content_disposition_test.dart' as content_disposition_test;
import 'routing/route_test.dart' as route_test;
import 'routing/router_test.dart' as router_test;
import 'uri/uri_builder_test.dart' as uri_builder_test;
import 'path/path_pattern_parser_test.dart' as path_pattern_parser_test;
import 'utils/web_utils_path_test.dart' as web_utils_path_test;
import 'utils/utils_test.dart' as utils_test;
import 'handler_cache_test.dart' as handler_cache_test;
import 'src/io_rest_test.dart' as io_rest_test;
import 'exception/exceptions_test.dart' as exceptions_test;
import 'cors/cors_test.dart' as cors_test;
import 'csrf/csrf_test.dart' as csrf_test;
import 'annotation/annotation_test.dart' as annotation_test;
import 'env/environment_test.dart' as environment_test;
import 'converter/converter_test.dart' as converter_test;
import 'web/web_test.dart' as web_test;
import 'context/context_test.dart' as context_test;
import 'io/io_test.dart' as io_test;
import 'rest/rest_test.dart' as rest_test;
import 'server/handler_test.dart' as handler_test;
import 'server/filter_test.dart' as filter_test;
import 'server/return_value_test.dart' as return_value_test;
import 'server/dispatcher_test.dart' as dispatcher_test;
import 'config/config_test.dart' as config_test;

void main() {
  group('HTTP', () {
    group('HttpMethod', http_method_test.main);
    group('HttpStatus', http_status_test.main);
    group('MediaType', media_type_test.main);
    group('HttpCookie', http_cookie_test.main);
    group('HttpRange', http_range_test.main);
    group('ETag', etag_test.main);
    group('CacheControl', cache_control_test.main);
    group('ContentDisposition', content_disposition_test.main);
  });

  group('Routing', () {
    group('Route', route_test.main);
    group('Router', router_test.main);
  });

  group('URI', () {
    group('UriBuilder', uri_builder_test.main);
  });

  group('Path', () {
    group('PathPatternParser', path_pattern_parser_test.main);
  });

  group('Utils', () {
    group('WebUtilsPath', web_utils_path_test.main);
    group('Utils', utils_test.main);
  });

  group('Exception', exceptions_test.main);
  group('CORS', cors_test.main);
  group('CSRF', csrf_test.main);
  group('Annotation', annotation_test.main);
  group('Environment', environment_test.main);
  group('Converter', converter_test.main);
  group('Web', web_test.main);
  group('Context', context_test.main);
  group('IO', io_test.main);
  group('REST', rest_test.main);
  group('Server', () {
    group('Handler', handler_test.main);
    group('Filter', filter_test.main);
    group('ReturnValue', return_value_test.main);
    group('Dispatcher', dispatcher_test.main);
  });
  group('Config', config_test.main);
  group('Handler Cache', handler_cache_test.main);
  group('IO REST', io_rest_test.main);
}
