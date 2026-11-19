import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/env.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';
import '../../../lang/meta/test_data.dart' show ensureTestAotRegistered;


class TestPodFactoryCustomizer implements PodFactoryCustomizer<ApplicationContext> {
  bool customized = false;

  @override
  Future<void> customize(ApplicationContext podFactory, Environment environment) async {
    customized = true;
  }
}

@JetleafTest()
Future<void> main() async {
  await ensureTestAotRegistered();
  group('PodFactoryCustomizer', () {
    test('should customize factory', () async {
      final customizer = TestPodFactoryCustomizer();
      final context = AnnotationConfigApplicationContext();

      await customizer.customize(context, context.getEnvironment());

      expect(customizer.customized, isTrue);
    });
  });
}