import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class TestPodFactoryCustomizer implements PodFactoryCustomizer<ApplicationContext> {
  bool customized = false;

  @override
  Future<void> customize(ApplicationContext podFactory, Environment environment) async {
    customized = true;
  }
}

@JetleafTest()
void main() {
  group('PodFactoryCustomizer', () {
    test('should customize factory', () async {
      final customizer = TestPodFactoryCustomizer();
      final context = AnnotationConfigApplicationContext();

      await customizer.customize(context, context.getEnvironment());

      expect(customizer.customized, isTrue);
    });
  });
}