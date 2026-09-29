// test/disposable_pod_test.dart
import 'package:jetleaf_pod/src/lifecycle/lifecycle.dart';
import 'package:test/test.dart';

class TestDisposablePod implements DisposablePod {
  bool destroyed = false;
  
  @override
  Future<void> onDestroy() async {
    destroyed = true;
  }
  
  @override
  String getPackageName() => 'test.package';
}

void main() {
  group('DisposablePod', () {
    test('should be an abstract interface', () {
      final pod = TestDisposablePod();
      expect(pod, isA<DisposablePod>());
    });
    
    test('should have onDestroy method', () async {
      final pod = TestDisposablePod();
      expect(() async => await pod.onDestroy(), returnsNormally);
    });
    
    test('onDestroy should be callable', () async {
      final pod = TestDisposablePod();
      expect(pod.destroyed, isFalse);
      await pod.onDestroy();
      expect(pod.destroyed, isTrue);
    });
    
    test('should have getPackageName method', () {
      final pod = TestDisposablePod();
      expect(pod.getPackageName(), equals('test.package'));
    });
  });
}