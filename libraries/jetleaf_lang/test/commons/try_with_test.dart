import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class _TestResource implements Closeable {
  bool closed = false;
  final List<String> log;

  _TestResource(this.log);

  @override
  Future<void> close() async {
    log.add('closed');
    closed = true;
  }
}

class _SyncCloseResource implements Closeable {
  bool closed = false;
  final List<String> log;

  _SyncCloseResource(this.log);

  @override
  void close() {
    log.add('sync closed');
    closed = true;
  }
}

void main() {
  group('${Constant.ICON} tryWith', () {
    test('should call close after successful async operation', () async {
      final log = <String>[];
      final resource = _TestResource(log);

      await tryWith<_TestResource>(resource, (res) async {
        log.add('using resource');
      });

      expect(log, ['using resource', 'closed']);
      expect(resource.closed, isTrue);
    });

    test('should call close after throwing in async action', () async {
      final log = <String>[];
      final resource = _TestResource(log);

      expect(
        () => tryWith(resource, (res) async {
          log.add('using resource');
          throw Exception('Something went wrong');
        }),
        throwsA(isA<Exception>()),
      );

      await Future.delayed(Duration.zero); // flush close()
      expect(log, ['using resource', 'closed']);
      expect(resource.closed, isTrue);
    });

    test('should support sync close and sync action', () async {
      final log = <String>[];
      final resource = _SyncCloseResource(log);

      await tryWith<_SyncCloseResource>(resource, (res) {
        log.add('sync use');
      });

      expect(log, ['sync use', 'sync closed']);
      expect(resource.closed, isTrue);
    });

    test('can nest tryWith calls with separate resources', () async {
      final log = <String>[];
      final outer = _TestResource(log);
      final inner = _SyncCloseResource(log);

      await tryWith<_TestResource>(outer, (o) async {
        log.add('outer begin');
        await tryWith<_SyncCloseResource>(inner, (i) {
          log.add('inner work');
        });
        log.add('outer end');
      });

      expect(
        log,
        ['outer begin', 'inner work', 'sync closed', 'outer end', 'closed'],
      );
    });
  });
}