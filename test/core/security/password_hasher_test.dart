import 'dart:convert';
import 'dart:typed_data';

import 'package:aviation_inventory/core/security/password_hasher.dart';
import 'package:test/test.dart';

/// Convierte un vector de prueba escrito en hexadecimal a bytes.
Uint8List hex(String value) {
  final clean = value.replaceAll(RegExp(r'\s+'), '');
  final bytes = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

/// Compara la salida base64url de [derive] contra un vector hexadecimal.
void expectMatchesVector({
  required String actualBase64Url,
  required String expectedHex,
}) {
  final actual = base64.decode(base64Url.normalize(actualBase64Url));
  expect(
    actual,
    hex(expectedHex),
    reason: 'esperado: ${hex(expectedHex)}\n'
        'obtenido:  $actual',
  );
}

void main() {
  group('PBKDF2-HMAC-SHA256 contra vectores de RFC 7914 sec. 11', () {
    test('P="passwd" S="salt" c=1 dkLen=64', () {
      expectMatchesVector(
        actualBase64Url: derive(
          password: 'passwd',
          salt: 'salt',
          iterations: 1,
          keyLength: 64,
        ),
        expectedHex:
            '55ac046e56e3089fec1691c22544b605'
            'f94185216dde0465e68b9d57c20dacbc'
            '49ca9cccf179b645991664b39d77ef31'
            '7c71b845b1e30bd509112041d3a19783',
      );
    });

    test('P="Password" S="NaCl" c=80000 dkLen=64', () {
      expectMatchesVector(
        actualBase64Url: derive(
          password: 'Password',
          salt: 'NaCl',
          iterations: 80000,
          keyLength: 64,
        ),
        expectedHex:
            '4ddcd8f60b98be21830cee5ef22701f9'
            '641a4418d04c0414aeff08876b34ab56'
            'a1d425a1225833549adb841b51c9b317'
            '6a272bdebba1d078478f62b397f33c8d',
      );
    });
  });

  group('PBKDF2-HMAC-SHA256 propiedades', () {
    test('produce exactamente keyLength bytes', () {
      for (final len in [16, 20, 32, 64]) {
        final got = derive(
          password: 'clave',
          salt: 'sal',
          iterations: 100,
          keyLength: len,
        );
        expect(base64Url.decode(got).length, len, reason: 'keyLength=$len');
      }
    });

    test('salt distinto produce hash distinto', () {
      final a = derive(password: 'x', salt: 'a', iterations: 100, keyLength: 32);
      final b = derive(password: 'x', salt: 'b', iterations: 100, keyLength: 32);
      expect(a, isNot(b));
    });

    test('mas iteraciones cambian el resultado', () {
      final a = derive(password: 'x', salt: 's', iterations: 100, keyLength: 32);
      final b = derive(password: 'x', salt: 's', iterations: 200, keyLength: 32);
      expect(a, isNot(b));
    });

    test('contrasena distinta produce hash distinto', () {
      final a = derive(password: 'x', salt: 's', iterations: 100, keyLength: 32);
      final b = derive(password: 'y', salt: 's', iterations: 100, keyLength: 32);
      expect(a, isNot(b));
    });
  });

  group('constantTimeEquals', () {
    test('igualdad y desigualdad', () {
      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'abcd'), isFalse);
      expect(constantTimeEquals('', ''), isTrue);
    });
  });

  group('PasswordHasher', () {
    const hasher = PasswordHasher(iterations: 1000);

    test('generateSalt produce salts distintos', () {
      final salts = List.generate(20, (_) => hasher.generateSalt());
      expect(salts.toSet().length, 20);
    });

    test('matches acepta la correcta y rechaza el resto', () {
      final salt = hasher.generateSalt();
      final params = Pbkdf2Params(
        salt: salt,
        iterations: hasher.iterations,
        keyLength: hasher.keyLength,
        hash: hasher.hash(password: 'correcta', salt: salt),
      );
      expect(hasher.matches(password: 'correcta', params: params), isTrue);
      expect(hasher.matches(password: 'incorrecta', params: params), isFalse);
      expect(hasher.matches(password: '', params: params), isFalse);
      expect(hasher.matches(password: 'Correcta', params: params), isFalse);
    });
  });
}
