// Nucleo criptografico. Deliberadamente **solo Dart puro**: sin
// `package:flutter`, para poder ejecutarse desde `dart run tool/...`.
// El wrapper con isolate esta en `hash_runner.dart`.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Identificador del KDF. Se persiste junto al hash para poder migrar
/// parametros en el futuro (subir iteraciones, cambiar a Argon2id, etc.)
/// sin romper las credenciales existentes.
const String kPasswordAlgorithm = 'pbkdf2-hmac-sha256';

/// Tamano del bloque de salida de SHA-256, en bytes.
const int _sha256BlockSize = 32;

/// Parametros de una credencial almacenada.
///
/// Nunca se guarda la contrasena: solo el `salt` y el `hash` derivado.
class Pbkdf2Params {
  const Pbkdf2Params({
    required this.salt,
    required this.iterations,
    required this.keyLength,
    required this.hash,
  });

  /// Salt aleatorio en base64url.
  final String salt;

  /// Iteraciones usadas cuando se genero el hash.
  final int iterations;

  /// Longitud en bytes de la clave derivada.
  final int keyLength;

  /// Clave derivada en base64url.
  final String hash;

  @override
  String toString() =>
      'Pbkdf2Params($kPasswordAlgorithm, it=$iterations, len=$keyLength)';
}

/// Derivacion de contrasenas con PBKDF2-HMAC-SHA256.
///
/// ### Por que esto y no "encriptar" la contrasena
///
/// Una contrasena no se cifra: se deriva. Cifrar es reversible (necesitas la
/// clave para recuperar el original), lo que para una contrasena significa que
/// cualquiera con acceso al almacenamiento la obtiene. Lo correcto es una
/// funcion de derivacion de un solo sentido (KDF) con salt e iteraciones.
///
/// ### Limite real de esta implementacion
///
/// Protege el dato **en reposo**: si alguien lee el binario de la app veria un
/// hash, no la contrasena. NO protege contra un atacante que controle el
/// dispositivo, porque la verificacion ocurre en el cliente y ese atacante
/// puede simplemente leer la constante y saltarse el login.
///
/// Cuando exista backend, la verificacion debe ocurrir **unicamente en el
/// servidor** y el cliente solo enviar la contrasena por HTTPS. Ver
/// `lib/features/auth/data/repositories/auth_repository_impl.dart`.
class PasswordHasher {
  const PasswordHasher({
    this.iterations = defaultIterations,
    this.keyLength = defaultKeyLength,
  });

  /// Iteraciones por defecto.
  ///
  /// OWASP recomienda 600 000 para PBKDF2-HMAC-SHA256, pero eso aplica a
  /// validacion **en servidor**. Aqui la comprobacion es local (demo), asi que
  /// se usa un valor que mantiene el login fluido (~100 ms).
  static const int defaultIterations = 12_000;

  static const int defaultKeyLength = 32;
  static const int _saltLength = 16;

  final int iterations;
  final int keyLength;

  static final Random _secureRandom = Random.secure();

  /// Genera un salt criptograficamente aleatorio en base64url.
  String generateSalt({int length = _saltLength}) {
    final bytes = List<int>.generate(length, (_) => _secureRandom.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Deriva el hash de una contrasena. Bloquea: ejecuta esto en un isolate
  /// desde la app (ver `hash_runner.dart`).
  String hash({required String password, required String salt}) {
    return derive(
      password: password,
      salt: salt,
      iterations: iterations,
      keyLength: keyLength,
    );
  }

  /// Comprueba una contrasena contra unas credenciales, en tiempo constante.
  bool matches({required String password, required Pbkdf2Params params}) {
    final derived = derive(
      password: password,
      salt: params.salt,
      iterations: params.iterations,
      keyLength: params.keyLength,
    );
    return constantTimeEquals(derived, params.hash);
  }

  /// Ejecuta una derivacion "de relleno" con parametros ficticios.
  ///
  /// Se usa cuando el usuario no existe. Sin esto, el login fallaria de forma
  /// instantanea para un usuario inexistente y lentamente para uno existente,
  /// lo que permite enumerar usuarios midiendo tiempos de respuesta.
  void burnTiming({String salt = 'timing-equalizer'}) {
    derive(
      password: 'timing-equalizer',
      salt: salt,
      iterations: iterations,
      keyLength: keyLength,
    );
  }
}

/// PBKDF2 con HMAC-SHA256 como PRF (RFC 8018).
String derive({
  required String password,
  required String salt,
  required int iterations,
  required int keyLength,
}) {
  return base64UrlEncode(
    _pbkdf2(
      password: utf8.encode(password),
      salt: utf8.encode(salt),
      iterations: iterations,
      keyLength: keyLength,
    ),
  );
}

Uint8List _pbkdf2({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int keyLength,
}) {
  final prf = Hmac(sha256, password);
  final blockCount = (keyLength / _sha256BlockSize).ceil();

  final output = Uint8List(keyLength);
  var offset = 0;

  for (var block = 1; block <= blockCount; block++) {
    // U1 = PRF(password, salt || INT_32_BE(block))
    var u = prf.convert(<int>[...salt, ..._int32BigEndian(block)]).bytes;
    final acc = Uint8List.fromList(u);

    // acc = U1 XOR U2 XOR ... XOR Uc
    for (var i = 1; i < iterations; i++) {
      u = prf.convert(u).bytes;
      for (var j = 0; j < acc.length; j++) {
        acc[j] ^= u[j];
      }
    }

    final remaining = keyLength - offset;
    final take = remaining < _sha256BlockSize ? remaining : _sha256BlockSize;
    output.setRange(offset, offset + take, acc.take(take));
    offset += take;
  }

  return output;
}

Uint8List _int32BigEndian(int value) {
  final bytes = Uint8List(4);
  ByteData.view(bytes.buffer).setUint32(0, value, Endian.big);
  return bytes;
}

/// Compara dos cadenas sin filtrar informacion por analisis temporal.
bool constantTimeEquals(String a, String b) {
  final x = utf8.encode(a);
  final y = utf8.encode(b);

  // La longitud se revela, pero es un dato publico (longitud del hash fijo).
  if (x.length != y.length) return false;

  var diff = 0;
  for (var i = 0; i < x.length; i++) {
    diff |= x[i] ^ y[i];
  }
  return diff == 0;
}
