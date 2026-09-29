import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/cache_control.dart';

void main() {
  group('CacheControl - Factory Constructors', () {
    test('empty has no directives', () {
      expect(CacheControl.empty().getHeaderValue(), isNull);
    });

    test('maxAge sets max-age directive', () {
      expect(CacheControl.maxAge(Duration(seconds: 300)).getHeaderValue(), 'max-age=300');
    });

    test('noCache sets no-cache directive', () {
      expect(CacheControl.noCache().getHeaderValue(), 'no-cache');
    });

    test('noStore sets no-store directive', () {
      expect(CacheControl.noStore().getHeaderValue(), 'no-store');
    });
  });

  group('CacheControl - Fluent Methods', () {
    test('mustRevalidate adds directive', () {
      expect(CacheControl.empty().mustRevalidate().getHeaderValue(), 'must-revalidate');
    });

    test('cachePublic adds directive', () {
      expect(CacheControl.empty().cachePublic().getHeaderValue(), 'public');
    });

    test('cachePrivate adds directive', () {
      expect(CacheControl.empty().cachePrivate().getHeaderValue(), 'private');
    });

    test('immutable adds directive', () {
      expect(CacheControl.empty().immutable().getHeaderValue(), 'immutable');
    });

    test('noTransform adds directive', () {
      expect(CacheControl.empty().noTransform().getHeaderValue(), 'no-transform');
    });

    test('proxyRevalidate adds directive', () {
      expect(CacheControl.empty().proxyRevalidate().getHeaderValue(), 'proxy-revalidate');
    });

    test('sMaxAge adds directive', () {
      expect(CacheControl.empty().sMaxAge(Duration(seconds: 600)).getHeaderValue(), 's-maxage=600');
    });

    test('staleWhileRevalidate adds directive', () {
      expect(CacheControl.empty().staleWhileRevalidate(Duration(seconds: 60)).getHeaderValue(), 'stale-while-revalidate=60');
    });

    test('staleIfError adds directive', () {
      expect(CacheControl.empty().staleIfError(Duration(seconds: 120)).getHeaderValue(), 'stale-if-error=120');
    });
  });

  group('CacheControl - Combined Directives', () {
    test('maxAge with public and mustRevalidate', () {
      final cc = CacheControl.maxAge(Duration(seconds: 300))
          .cachePublic()
          .mustRevalidate();
      expect(cc.getHeaderValue(), 'max-age=300, must-revalidate, public');
    });

    test('noStore combined with mustRevalidate', () {
      final cc = CacheControl.noStore().mustRevalidate();
      expect(cc.getHeaderValue(), contains('no-store'));
      expect(cc.getHeaderValue(), contains('must-revalidate'));
    });

    test('private with immutable', () {
      final cc = CacheControl.empty().cachePrivate().immutable();
      expect(cc.getHeaderValue(), 'private, immutable');
    });
  });

  group('CacheControl - toString()', () {
    test('formats header value', () {
      expect(CacheControl.maxAge(Duration(seconds: 60)).toString(), 'CacheControl [max-age=60]');
    });
  });
}