import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultProcessInformation', () {
    test('should create with RSS values', () {
      final info = DefaultProcessInformation(1024 * 1024, 512 * 1024, 2048 * 1024);
      expect(info.getCurrentResidentSetSizeMemory().value, equals(1024 * 1024));
      expect(info.getFreedMemory().value, equals(512 * 1024));
      expect(info.getMaxResidentSetSizeMemory().value, equals(2048 * 1024));
    });

    test('should return current RSS as Integer', () {
      final info = DefaultProcessInformation(100, 0, 200);
      expect(info.getCurrentResidentSetSizeMemory(), isA<Integer>());
      expect(info.getCurrentResidentSetSizeMemory().value, equals(100));
    });

    test('should return freed memory as Integer', () {
      final info = DefaultProcessInformation(100, 50, 200);
      expect(info.getFreedMemory().value, equals(50));
    });

    test('should return max RSS as Integer', () {
      final info = DefaultProcessInformation(100, 0, 200);
      expect(info.getMaxResidentSetSizeMemory().value, equals(200));
    });

    test('should return platform operating system', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getOperatingSystem(), isA<String>());
      expect(info.getOperatingSystem().isNotEmpty, isTrue);
    });

    test('should return platform OS version', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getOperatingSystemVersion(), isA<String>());
      expect(info.getOperatingSystemVersion().isNotEmpty, isTrue);
    });

    test('should return number of processors', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getNumberOfProcessors(), isA<Integer>());
      expect(info.getNumberOfProcessors().value, greaterThan(0));
    });

    test('should return Dart version', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getDartVersion(), isA<String>());
      expect(info.getDartVersion().isNotEmpty, isTrue);
    });

    test('should return local host name', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getLocalHostName(), isA<String>());
      expect(info.getLocalHostName().isNotEmpty, isTrue);
    });

    test('should return locale name', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getLocaleName(), isA<String>());
      expect(info.getLocaleName().isNotEmpty, isTrue);
    });

    test('should serialize to JSON', () {
      final info = DefaultProcessInformation(1024, 512, 2048);
      final json = info.toJson();
      expect(json['system.current.resident.set.size'], equals(1024));
      expect(json['system.freed.memory'], equals(512));
      expect(json['system.max.resident.set.size'], equals(2048));
      expect(json['dart.version'], isA<String>());
      expect(json['os.name'], isA<String>());
      expect(json['os.version'], isA<String>());
      expect(json['system.locale'], isA<String>());
      expect(json['system.hostname'], isA<String>());
      expect(json['system.processors'], isA<int>());
    });

    test('should implement ProcessInformation interface', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info, isA<ProcessInformation>());
    });

    test('should have equalizedProperties', () {
      final info = DefaultProcessInformation(100, 50, 200);
      final props = info.equalizedProperties();
      expect(props.length, equals(3));
      expect(props[0], equals(100));
      expect(props[1], equals(50));
      expect(props[2], equals(200));
    });

    test('should implement EqualsAndHashCode', () {
      final i1 = DefaultProcessInformation(100, 50, 200);
      expect(i1, isA<EqualsAndHashCode>());
    });

    test('should not be equal with different values', () {
      final i1 = DefaultProcessInformation(100, 0, 0);
      final i2 = DefaultProcessInformation(200, 0, 0);
      expect(i1, isNot(equals(i2)));
    });

    test('should handle zero values', () {
      final info = DefaultProcessInformation(0, 0, 0);
      expect(info.getCurrentResidentSetSizeMemory().value, equals(0));
      expect(info.getFreedMemory().value, equals(0));
      expect(info.getMaxResidentSetSizeMemory().value, equals(0));
    });
  });
}
