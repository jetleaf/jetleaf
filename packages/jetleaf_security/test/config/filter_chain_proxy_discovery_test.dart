import 'package:jetleaf_core/lang.dart' show Class;
import 'package:jetleaf_core/pod.dart'
    show DefaultListablePodFactory, RootPodDefinition;
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:test/test.dart';

void main() {
  group('FilterChainProxy discovery', () {
    test('the default pod collects every SecurityFilterChain pod', () async {
      final factory = DefaultListablePodFactory();
      final first = SecurityFilterChain(
        requestMatcher: PathPatternMatcher('/first/**'),
        filters: const [],
        order: 0,
      );
      final second = SecurityFilterChain(
        requestMatcher: PathPatternMatcher('/second/**'),
        filters: const [],
        order: 1,
      );

      for (final MapEntry(:key, :value) in {
        'firstChain': first,
        'secondChain': second,
      }.entries) {
        await factory.registerDefinition(
          key,
          RootPodDefinition(
            type: Class<SecurityFilterChain>(),
            instanceSupplier: (_) async => value,
          )..name = key,
        );
      }

      final proxy = await SecurityAutoConfiguration().filterChainProxy(factory);

      expect(proxy.chains, hasLength(2));
      expect(proxy.chains, contains(same(first)));
      expect(proxy.chains, contains(same(second)));
    });

    test('filter and chain order is exposed through Ordered.getOrder()', () {
      final chain = SecurityFilterChain(
        requestMatcher: const AnyRequestMatcher(),
        filters: const [],
        order: 7,
      );
      expect(chain.getOrder(), 7);
    });
  });
}