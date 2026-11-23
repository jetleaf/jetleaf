import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Published Favre OpenBSD BCrypt test vectors. These are independent of the
/// implementation under test — the hashes are fixed strings from the
/// published vector suite.
void main() {
  group('BCrypt published vectors', () {
    final encoder = BCryptPasswordEncoder(strength: 4, version: '2a');

    test('empty password', () {
      expect(
        encoder.matches(
          '',
          r'$2a$04$zVHmKQtGGQob.b/Nc7l9NO8UlrYcW05FiuCj/SxsFO/ZtiN9.mNzy',
        ),
        isTrue,
      );
    });

    test('single-character password', () {
      expect(
        encoder.matches(
          'a',
          r'$2a$04$5DCebwootqWMCp59ISrMJ.l4WvgHIVg17ZawDIrDM2IjlE64GDNQS',
        ),
        isTrue,
      );
    });

    test('non-ASCII password', () {
      expect(
        encoder.matches(
          'àèìòùÀÈÌÒÙáéíóúýÁÉÍÓÚÝðÐ',
          r'$2a$04$D3qS2aoTVyqM7z8v8crLm.3nKt4CzBZJbyFB.ZebmfCvRw7BGs.Xm',
        ),
        isTrue,
      );
    });

    test('password beyond the 72-byte truncation boundary', () {
      expect(
        encoder.matches(
          'g*3Q45="8NNgpT&mbMJ\$Omfr.#ZeW?FP=CE\$#roHd?97uL0F-]`?u73c"\\[."*)qU34@VG',
          r'$2a$04$T2XJ5MOWvHQZRijl8LIKkOQKIyX75KBfuLsuRYOJz5OjwBNF2lM8a',
        ),
        isTrue,
      );
    });
  });
}
