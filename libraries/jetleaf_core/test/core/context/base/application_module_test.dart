import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';
import '../../../lang/meta/test_data.dart' show ensureTestAotRegistered;


class TestModule implements ApplicationModule {
  bool configured = false;

  @override
  Future<void> configure(ApplicationContext context) async {
    configured = true;
  }

  @override
  List<Object?> equalizedProperties() => [TestModule];
}

@JetleafTest()
Future<void> main() async {
  await ensureTestAotRegistered();
  group('ApplicationModule', () {
    test('should configure context', () async {
      final customizer = TestModule();
      final context = AnnotationConfigApplicationContext();

      await customizer.configure(context);

      expect(customizer.configured, isTrue);
    });
  });
}