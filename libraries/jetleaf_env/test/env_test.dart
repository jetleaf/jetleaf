import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  group('StandardEnvironment', () {
    late GlobalEnvironment env;

    setUp(() {
      env = GlobalEnvironment();
      env.getPropertySources().addFirst(MapPropertySource('testSource', {
        'app.name': 'Jetleaf',
        'app.version': '1.0.0',
        'server.port': '8080',
        'greeting': 'Hello, #{app.name}!',
        'welcome': 'Welcome to #{app.name} version v#{app.version}',
      }));
    });

    test('containsProperty returns true for existing key', () {
      expect(env.containsProperty('app.name'), isTrue);
    });

    test('getProperty returns correct value', () {
      expect(env.getProperty('app.name'), equals('Jetleaf'));
    });

    test('getRequiredProperty throws on missing key', () {
      expect(() => env.getRequiredProperty('missing.key'), throwsA(isA<Exception>()));
    });

    test('resolvePlaceholders resolves nested placeholders', () {
      expect(env.getProperty("greeting"), equals('Hello, Jetleaf!'));
    });

    test('resolvePlaceholders with mixed syntax', () {
      expect(env.getProperty("welcome"), equals('Welcome to Jetleaf version v1.0.0'));
    });

    test('activeProfiles is initially empty', () {
      expect(env.getActiveProfiles(), isEmpty);
    });

    test('can set active and default profiles', () {
      env.setDefaultProfiles(['dev']);
      env.setActiveProfiles(['prod']);
      expect(env.getActiveProfiles(), contains('prod'));
      expect(env.getDefaultProfiles(), contains('dev'));
    });
  });
}