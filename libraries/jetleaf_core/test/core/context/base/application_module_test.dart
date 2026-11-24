import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';
import '../../../lang/meta/test_data.dart' show ensureTestAotRegisteredSync;


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
  ensureTestAotRegisteredSync();
  group('ApplicationModule', () {
    test('should configure context', () async {
      final customizer = TestModule();
      final context = AnnotationConfigApplicationContext();

      await customizer.configure(context);

      expect(customizer.configured, isTrue);
    });
  });
}