import 'package:jetleaf_core/context.dart' show PodFactoryPostProcessor;
import 'package:jetleaf_core/pod.dart' show ConfigurableListablePodFactory;

import 'package:jetleaf_security/config.dart' show SecurityAutoConfiguration;
import 'package:jetleaf_security/filter.dart' show FilterChainProxy;

/// Removes the framework's default chain and proxy when the example installs
/// its own multi-chain [FilterChainProxy] bean.
final class FilterChainOverridePostProcessor implements PodFactoryPostProcessor {
  FilterChainOverridePostProcessor();

  static const exampleProxy = 'example.filterChainProxy';

  @override
  Future<void> postProcessFactory(
    ConfigurableListablePodFactory podFactory,
  ) async {
    if (!podFactory.containsDefinition(exampleProxy)) return;
    for (final name in [
      SecurityAutoConfiguration.FILTER_CHAIN_PROXY,
      SecurityAutoConfiguration.FILTER_CHAIN,
    ]) {
      if (podFactory.containsDefinition(name)) {
        await podFactory.removeDefinition(name);
      }
    }
  }
}
