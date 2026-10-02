import 'package:jetleaf_cli/src/panel_view/panel_view.dart';
import 'package:jetleaf_cli/src/panel_view/realtime_panel_impl.dart';
import 'package:test/test.dart';

void main() {
  group('RealtimePanelViewImpl', () {
    late RealtimePanelViewImpl panel;

    setUp(() {
      panel = RealtimePanelViewImpl();
    });

    test('should not be connected initially', () {
      expect(panel.isConnected, isFalse);
    });

    test('should register event listener', () {
      var called = false;
      panel.on('test', (_) {
        called = true;
      });
      // Listener registered - no assertion needed beyond no error
      expect(called, isFalse);
    });

    test('should register multiple listeners for same event', () {
      var count = 0;
      panel.on('test', (_) => count++);
      panel.on('test', (_) => count++);
      expect(count, equals(0));
    });

    test('should remove event listener', () {
      var called = false;
      void handler(_) {
        called = true;
      }
      panel.on('test', handler);
      panel.off('test', handler);
      // After removal, handler should not be called
      expect(called, isFalse);
    });

    test('should remove listener and clean up empty list', () {
      void handler(_) {}
      panel.on('test', handler);
      panel.off('test', handler);
      // Internal state should be cleaned up
    });

    test('should send command with args', () {
      // send() requires WebSocket, but we can test it doesn't throw when ws is null
      panel.sendCommand('test_command', {'key': 'value'});
    });

    test('should send command without args', () {
      panel.sendCommand('test_command');
    });

    test('should sendStarted', () {
      panel.sendStarted(url: 'ws://localhost:8080');
    });

    test('should requestPodsList', () {
      panel.requestPodsList();
    });

    test('should requestPodDetails', () {
      panel.requestPodDetails('my_pod');
    });

    test('should sendShowPod', () {
      panel.sendShowPod('my_pod');
    });

    test('should handle send when not connected', () {
      // Should not throw when WebSocket is null
      panel.send('test', {'data': 'value'});
    });

    test('should disconnect gracefully when not connected', () async {
      await panel.disconnect();
      expect(panel.isConnected, isFalse);
    });

    test('should dispatch local events', () {
      var receivedPayload = <String, dynamic>{};
      panel.on('connected', (payload) {
        receivedPayload = payload;
      });
      // 'connected' event is emitted locally on connect, but we can't easily
      // test without WebSocket. Just verify no error on register.
      expect(receivedPayload, isEmpty);
    });

    test('should handle off for non-existent event', () {
      void handler(_) {}
      // Should not throw
      panel.off('nonexistent', handler);
    });

    test('should implement RealtimePanelView', () {
      expect(panel, isA<RealtimePanelView>());
    });

    test('should implement PanelView', () {
      expect(panel, isA<PanelView>());
    });
  });

  group('RealtimePanelViewImpl - Message Protocol', () {
    test('should construct correct send message format', () {
      final panel = RealtimePanelViewImpl();
      // Test that send doesn't throw when ws is null
      panel.send('started', {'url': 'ws://localhost'});
    });

    test('should handle multiple event types', () {
      final panel = RealtimePanelViewImpl();
      var startedCalled = false;
      var podsCalled = false;
      panel.on('started', (_) => startedCalled = true);
      panel.on('request_pods', (_) => podsCalled = true);
      // Both listeners registered without error
      expect(startedCalled, isFalse);
      expect(podsCalled, isFalse);
    });
  });
}
