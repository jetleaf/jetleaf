import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

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
void main() {
  group('ApplicationModule', () {
    test('should configure context', () async {
      final customizer = TestModule();
      final context = AnnotationConfigApplicationContext();

      await customizer.configure(context);

      expect(customizer.configured, isTrue);
    });
  });
}