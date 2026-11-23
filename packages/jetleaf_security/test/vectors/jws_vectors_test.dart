import 'dart:convert';

import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Known-answer vectors from RFC 7515 Appendix A.1 (HMAC SHA-256), A.2
/// (RSASSA-PKCS1-v1_5 SHA-256) and A.3 (ECDSA P-256 SHA-256).
const payload =
    'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ';

void main() {
  group('RFC 7515 JWS vectors', () {
    test('A.1 HS256 signature', () {
      const key = 'AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75'
          'aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow';
      const input =
          'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.$payload';
      const expected = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

      final signature = JwtCrypto.signHmac(
        JwsAlgorithms.hs256,
        JwtBase64Url.decode(key),
        utf8.encode(input),
      );

      expect(JwtBase64Url.encode(signature), equals(expected));
      expect(
        JwtCrypto.verifyHmac(
          JwsAlgorithms.hs256,
          JwtBase64Url.decode(key),
          utf8.encode(input),
          signature,
        ),
        isTrue,
      );
    });

    test('A.2 RS256 verification', () {
      const n = 'ofgWCuLjybRlzo0tZWJjNiuSfb4p4fAkd_wWJcyQoTbji9k0l8W26mPddx'
          'HmfHQp-Vaw-4qPCJrcS2mJPMEzP1Pt0Bm4d4QlL-yRT-SFd2lZS-pCgNMs'
          'D1W_YpRPEwOWvG6b32690r2jZ47soMZo9wGzjb_7OMg0LOL-bSf63kpaSH'
          'SXndS5z5rexMdbBYUsLA9e-KXBdQOS-UTo7WTBEMa2R2CapHg665xsmtdV'
          'MTBQY4uDZlxvb3qCo5ZwKh9kG4LT6_I5IhlJH7aGhyxXFvUK-DWNmoudF8'
          'NAco9_h9iaGNj8q2ethFkMLs91kzk2PAcDTW9gb54h4FRWyuXpoQ';
      const signature =
          'cC4hiUPoj9Eetdgtv3hF80EGrhuB__dzERat0XF9g2VtQgr9PJbu3XOiZj5RZmh7'
          'AAuHIm4Bh-0Qc_lF5YKt_O8W2Fp5jujGbds9uJdbF9CUAr7t1dnZcAcQjbKBYNX4'
          'BAynRFdiuB--f_nZLgrnbyTyWzO75vRK5h6xBArLIARNPvkSjtQBMHlb1L07Qe7K'
          '0GarZRmB_eSN9383LcOLn6_dO--xi12jzDwusC-eOkHWEsqtFZESc6BfI7noOPqv'
          'hJ1phCnvWh6IeYI2w9QOYEUipUTI8np6LbgGY9Fs98rqVt5AXLIhWkWywlVmtVrB'
          'p0igcN_IoypGlUPQGe77Rw';

      final input = utf8.encode('eyJhbGciOiJSUzI1NiJ9.$payload');

      expect(
        JwtCrypto.verifyRsa(
          JwsAlgorithms.rs256,
          n: JwtBase64Url.decodeInteger(n),
          e: JwtBase64Url.decodeInteger('AQAB'),
          data: input,
          signature: JwtBase64Url.decode(signature),
        ),
        isTrue,
      );
    });

    test('A.3 ES256 verification', () {
      const x = 'f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU';
      const y = 'x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0';
      const signature =
          'DtEhU3ljbEg8L38VWAfUAqOyKAM6-Xx-F4GawxaepmXFCgfTjDxw5djxLa8ISlSA'
          'pmWQxfKTUJqPP3-Kg6NU1Q';

      final input = utf8.encode('eyJhbGciOiJFUzI1NiJ9.$payload');

      expect(
        JwtCrypto.verifyEc(
          JwsAlgorithms.es256,
          x: JwtBase64Url.decodeInteger(x),
          y: JwtBase64Url.decodeInteger(y),
          data: input,
          signature: JwtBase64Url.decode(signature),
        ),
        isTrue,
      );
    });

    test('alg none and unknown algorithms are rejected by the decoder', () async {
      final decoder = DartJwtDecoder.withKey(
        const JwtSecretKey([1, 2, 3]),
      );
      const forged =
          'eyJhbGciOiJub25lIn0.eyJzdWIiOiJhbGljZSJ9.';

      await expectLater(
        decoder.decode(forged),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });
}
