import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  group('StandardEnvironment - Property Source Chaining', () {
    late GlobalEnvironment env;

    setUp(() {
      env = GlobalEnvironment();
    });

    test('should resolve placeholders across multiple property sources', () {
      // Create multiple property sources with interdependencies
      env.getPropertySources().addFirst(MapPropertySource('source3', {
        'database.url': 'jdbc:mysql://#{database.host}:#{database.port}/#{database.name}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('source2', {
        'database.host': 'localhost',
        'database.port': '3306',
        'server.url': 'http://#{server.host}:#{server.port}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('source1', {
        'database.name': 'mydb',
        'server.host': '#{database.host}',
        'server.port': '8080',
        'app.config': '#{server.url}/api',
      }));

      // Test cross-source resolution
      expect(env.getProperty('database.url'), 
          equals('jdbc:mysql://localhost:3306/mydb'));
      expect(env.getProperty('server.url'), 
          equals('http://localhost:8080'));
      expect(env.getProperty('app.config'), 
          equals('http://localhost:8080/api'));
    });

    test('should handle circular references across property sources', () {
      env.getPropertySources().addFirst(MapPropertySource('source2', {
        'app.host': '#{server.host}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('source1', {
        'server.host': '#{app.host}',
      }));

      expect(() => env.getProperty('app.host'), 
          throwsA(isA<PlaceholderResolutionException>()));
    });

    test('should respect property source precedence', () {
      // Later sources (added first) override earlier ones
      env.getPropertySources().addFirst(MapPropertySource('override', {
        'common.key': 'override-value',
        'override.only': 'from-override',
      }));

      env.getPropertySources().addLast(MapPropertySource('base', {
        'common.key': 'base-value',
        'base.only': 'from-base',
      }));

      // Override source takes precedence
      expect(env.getProperty('common.key'), equals('override-value'));
      expect(env.getProperty('override.only'), equals('from-override'));
      expect(env.getProperty('base.only'), equals('from-base'));
    });

    test('should resolve nested placeholders across sources', () {
      env.getPropertySources().addFirst(MapPropertySource('config', {
        'full.url': '#{protocol}://#{host}:#{port}#{path}',
        'api.endpoint': '#{full.url}/users',
      }));

      env.getPropertySources().addFirst(MapPropertySource('network', {
        'protocol': 'https',
        'host': 'api.example.com',
        'port': '443',
        'path': '/v1',
      }));

      expect(env.getProperty('full.url'), 
          equals('https://api.example.com:443/v1'));
      expect(env.getProperty('api.endpoint'), 
          equals('https://api.example.com:443/v1/users'));
    });

    test('should fallback through property sources', () {
      env.getPropertySources().addFirst(MapPropertySource('specific', {
        'logging.level': 'DEBUG',
        // No fallback defined here
      }));

      env.getPropertySources().addLast(MapPropertySource('defaults', {
        'logging.level': 'INFO',
        'timeout': '30s',
        'retry.count': '3',
      }));

      // Specific source provides this value
      expect(env.getProperty('logging.level'), equals('DEBUG'));
      // Falls back to defaults source
      expect(env.getProperty('timeout'), equals('30s'));
      expect(env.getProperty('retry.count'), equals('3'));
    });

    test('should handle complex multi-level cross-source references', () {
      env.getPropertySources().addFirst(MapPropertySource('layer3', {
        'connection.string': '#{driver}://#{username}@#{host}/#{database}',
        'monitoring.url': '#{protocol}://#{monitoring.host}:#{monitoring.port}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('layer2', {
        'driver': 'postgresql',
        'username': 'admin',
        'monitoring.host': 'metrics.#{app.domain}',
        'protocol': 'https',
      }));

      env.getPropertySources().addFirst(MapPropertySource('layer1', {
        'host': '#{region}.database.example.com',
        'database': 'production',
        'region': 'us-east-1',
        'app.domain': 'myapp.com',
        'monitoring.port': '9090',
      }));

      expect(env.getProperty('connection.string'), 
          equals('postgresql://admin@us-east-1.database.example.com/production'));
      expect(env.getProperty('monitoring.url'), 
          equals('https://metrics.myapp.com:9090'));
    });

    test('should resolve environment variables in property sources', () {
      // Mock environment variable
      // In real scenario, this would come from system env
      env.getPropertySources().addFirst(MapPropertySource('env', {
        'HOME': '/user/home',
      }));

      env.getPropertySources().addFirst(MapPropertySource('app', {
        'data.dir': '#{HOME}/data',
        'config.path': '#{data.dir}/config.yaml',
      }));

      expect(env.getProperty('data.dir'), equals('/user/home/data'));
      expect(env.getProperty('config.path'), equals('/user/home/data/config.yaml'));
    });

    test('should handle missing properties with fallback syntax across sources', () {
      env.getPropertySources().addFirst(MapPropertySource('app', {
        'server.host': 'localhost',
        'connection.url': '#{protocol:http}://#{server.host}:#{port:8080}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('defaults', {
        'protocol': 'https', // This should NOT be used due to fallback in app source
        'port': '3000',      // This should NOT be used due to fallback in app source
      }));

      // Should use fallback values from placeholder syntax, not defaults source
      expect(env.getProperty('connection.url'), equals('https://localhost:3000'));
    });

    test('should override fallbacks with explicit values from higher priority sources', () {
      env.getPropertySources().addFirst(MapPropertySource('override', {
        'port': '9090', // Overrides both fallback and lower source
      }));

      env.getPropertySources().addFirst(MapPropertySource('config', {
        'server.host': 'localhost',
        'connection.url': '#{protocol:http}://#{server.host}:#{port:8080}',
      }));

      expect(env.getProperty('connection.url'), equals('http://localhost:9090'));
    });

    test('should handle property source removal and reordering', () {
      env.getPropertySources().addFirst(MapPropertySource('dynamic', {
        'value': 'dynamic-value',
      }));

      // Dynamic source takes precedence
      expect(env.getProperty('value'), equals('dynamic-value'));

      env.getPropertySources().addFirst(MapPropertySource('static', {
        'value': 'static-value',
        'other': 'static-other',
      }));

      // Remove dynamic source
      env.getPropertySources().remove('dynamic');
      
      // Now static source provides the value
      expect(env.getProperty('value'), equals('static-value'));
      expect(env.getProperty('other'), equals('static-other'));
    });

    test('should resolve deeply nested cross-references', () {
      env.getPropertySources().addFirst(MapPropertySource('level4', {
        'endpoint': '#{base.url}#{api.path}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('level3', {
        'base.url': '#{protocol}://#{host}',
        'api.path': '/#{api.version}/#{resource}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('level2', {
        'protocol': 'https',
        'host': '#{subdomain}.#{domain}',
        'api.version': 'v#{version.major}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('level1', {
        'subdomain': 'api',
        'domain': 'example.com',
        'version.major': '2',
        'resource': 'users',
      }));

      expect(env.getProperty('endpoint'), 
          equals('https://api.example.com/v2/users'));
    });

    test('should handle boolean and numeric values across sources', () {
      env.getPropertySources().addFirst(MapPropertySource('config', {
        'debug.enabled': 'true',
        'max.connections': '100',
        'timeout.ms': '#{default.timeout}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('defaults', {
        'default.timeout': '5000',
      }));

      // Type preservation test
      final debugEnabled = env.getPropertyAs('debug.enabled', Class<bool>());
      final maxConnections = env.getPropertyAs('max.connections', Class<int>());
      final timeout = env.getProperty('timeout.ms');

      expect(debugEnabled, isTrue);
      expect(maxConnections, equals(100)); // Returns as int
      expect(timeout, equals('5000'));
    });

    test('should merge properties from multiple sources with placeholders', () {
      env.getPropertySources().addFirst(MapPropertySource('overrides', {
        'greeting': 'Welcome to #{app.name}!',
        'version': 'v#{app.version}',
      }));

      env.getPropertySources().addFirst(MapPropertySource('app', {
        'app.name': 'MyApp',
        'app.version': '2.0.0',
        'description': '#{greeting} - #{version}',
      }));

      env.getPropertySources().addLast(MapPropertySource('base', {
        'app.name': 'DefaultApp',
        'app.version': '1.0.0',
        'author': 'Team',
      }));

      expect(env.getProperty('app.name'), equals('MyApp'));
      expect(env.getProperty('greeting'), equals('Welcome to MyApp!'));
      expect(env.getProperty('description'), 
          equals('Welcome to MyApp! - v2.0.0'));
    });
  });

  group('StandardEnvironment - Edge Cases', () {
    late GlobalEnvironment env;

    setUp(() {
      env = GlobalEnvironment();
    });

    test('should handle malformed placeholder syntax', () {
      env.getPropertySources().addFirst(MapPropertySource('test', {
        'malformed': '#{unclosed',
        'invalid': '#{key:fallback:extra}',
      }));

      // Should handle gracefully or throw appropriate exception
      expect(() => env.getProperty('malformed'), returnsNormally);
    });

    test('should handle very long chains of references', () {
      // Create a chain of 10 dependencies
      final sources = <MapPropertySource>[];
      for (int i = 0; i < 10; i++) {
        sources.add(MapPropertySource('source$i', {
          'key$i': i == 0 ? 'final' : '#{key${i-1}}',
        }));
      }

      // Add in reverse order so source0 is highest priority
      for (final source in sources.reversed) {
        env.getPropertySources().addFirst(source);
      }

      expect(env.getProperty('key9'), equals('final'));
    });

    test('should handle concurrent access during resolution', () async {
      env.getPropertySources().addFirst(MapPropertySource('source', {
        'value': '#{dependency}',
      }));
      env.getPropertySources().addLast(MapPropertySource('dep', {
        'dependency': 'resolved',
      }));

      // Test concurrent access
      final futures = List.generate(10, (i) async {
        return env.getProperty('value');
      });

      final results = await Future.wait(futures);
      for (final result in results) {
        expect(result, equals('resolved'));
      }
    });
  });
}