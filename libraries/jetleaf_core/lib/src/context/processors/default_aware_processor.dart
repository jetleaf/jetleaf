import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../aware.dart';
import '../base/application_context.dart';
import '../core/abstract_application_context.dart';

/// {@template jetleaf_class_DefaultAwareProcessor}
/// 🫘 Default processor that injects Jetleaf "aware" contracts into pods.
///
/// [DefaultAwareProcessor] extends [PodProcessor] and implements
/// [PriorityOrdered], ensuring it runs at the highest precedence during
/// pod initialization.
///
/// ## Responsibilities
///
/// - Checks if a newly created pod implements any of the `*Aware` contracts,
///   and injects the corresponding dependency:
///   - [EnvironmentAware] → injects the current [Environment].
///   - [ApplicationContextAware] → injects the [ApplicationContext].
///   - [PodFactoryAware] → injects the [PodFactory].
///   - [PodNameAware] → injects the pod’s registration name.
///   - [ConversionServiceAware] → injects the [ConversionService].
///   - [MessageSourceAware] → injects the [MessageSource] (if available).
///   - [ApplicationEventBusAware] → injects the [ApplicationEventBus] (if available).
///
/// ## Ordering
///
/// This processor declares [Ordered.HIGHEST_PRECEDENCE], ensuring it runs
/// before other processors that may rely on these aware dependencies.
///
/// ## Example
///
/// ```dart
/// final context = MyApplicationContext();
/// final processor = DefaultAwareProcessor(context);
///
/// // When the pod factory creates a new pod, the processor ensures
/// // that any implemented Aware interfaces are populated.
/// ```
///
/// See also:
/// - [PodProcessor] 🫘 base class for processors.
/// - [PriorityOrdered] 🫘 for ordering processors.
/// - [PodInitializationProcessor] 🫘 for initialization-specific processing.
/// - [AbstractApplicationContext] 🫘 for extended context features.
///
/// {@endtemplate}
final class DefaultAwareProcessor extends PodInitializationProcessor implements PriorityOrdered {
  /// The application context this processor uses for dependency injection.
  final ApplicationContext applicationContext;
  final StringValueResolver _embeddedValueResolver;

  /// Creates a new [DefaultAwareProcessor] bound to the given [applicationContext].
  ///
  /// {@macro jetleaf_class_DefaultAwareProcessor}
  DefaultAwareProcessor(this.applicationContext) : _embeddedValueResolver = EmbeddedValueResolver(applicationContext.getPodFactory());

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE;

  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => true;

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    final podFactory = applicationContext.getPodFactory();
    final instance = pod;

    if (instance case EnvironmentAware environmentAware) {
      environmentAware.setEnvironment(applicationContext.getEnvironment());
    }

    if (instance case EmbeddedValueResolverAware embeddedValueResolverAware) {
      embeddedValueResolverAware.setEmbeddedValueResolver(_embeddedValueResolver);
    }

    if (instance case ApplicationContextAware applicationContextAware) {
      applicationContextAware.setApplicationContext(applicationContext);
    }

    if (instance case EntryApplicationAware entryApplicationAware) {
      entryApplicationAware.setEntryApplication(applicationContext.getMainApplicationClass());
    }

    if (instance case PodFactoryAware podFactoryAware) {
      podFactoryAware.setPodFactory(podFactory);
    }

    if (instance case PodNameAware podNameAware) {
      podNameAware.setPodName(name);
    }

    if (instance case ConversionServiceAware conversionServiceAware) {
      conversionServiceAware.setConversionService(podFactory.getConversionService());
    }

    if (applicationContext case ConfigurableApplicationContext aac) {
      if (instance case MessageSourceAware messageSourceAware) {
        messageSourceAware.setMessageSource(aac.getMessageSource());
      }

      if (instance case ApplicationEventBusAware applicationEventBusAware) {
        applicationEventBusAware.setApplicationEventBus(aac.getApplicationEventBus());
      }
    }

    return instance;
  }
}