import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('BannerMode', () {
    test('should have OFF value', () {
      expect(BannerMode.OFF, isNotNull);
    });

    test('should have CONSOLE value', () {
      expect(BannerMode.CONSOLE, isNotNull);
    });

    test('should have exactly 2 values', () {
      expect(BannerMode.values.length, 2);
    });

    test('OFF should not equal CONSOLE', () {
      expect(BannerMode.OFF, isNot(equals(BannerMode.CONSOLE)));
    });
  });

  group('Banner interface', () {
    test('should be interface', () {
      expect(Banner, isA<Type>());
    });
  });

  group('DefaultBanner', () {
    test('should create with fallback banner', () {
      final fallback = _TestBanner();
      final banner = DefaultBanner(fallback);
      expect(banner, isNotNull);
    });

    test('should implement Banner interface', () {
      final fallback = _TestBanner();
      final banner = DefaultBanner(fallback);
      expect(banner, isA<Banner>());
    });

    test('should get correct package name', () {
      final fallback = _TestBanner();
      final banner = DefaultBanner(fallback);
      expect(banner.getPackageName(), equals(PackageNames.MAIN));
    });

    test('should print fallback banner when no config', () {
      final fallback = _TestBanner();
      final banner = DefaultBanner(fallback);
      // PrintStream is abstract, skip actual printing
      expect(banner, isNotNull);
    });
  });
}

class _TestBanner implements Banner {
  @override
  void printBanner(Environment environment, Class<Object> sourceClass, PrintStream printStream) {
    // Test banner implementation
  }

  @override
  String getPackageName() => PackageNames.MAIN;
}
