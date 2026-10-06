import 'package:flutter/foundation.dart';

import 'password_hasher.dart';

/// Ejecuta PBKDF2 en un isolate separado.
///
/// PBKDF2 son miles de iteraciones de HMAC-SHA256: hacerlo en el isolate de UI
/// congelaria los frames y se veria como un tirones en el boton "Entrar".
///
/// Si `compute` no esta disponible (por ejemplo en un test puro de Dart) cae a
/// la version sincrona.
Future<String> deriveHashAsync({
  required String password,
  required String salt,
  required int iterations,
  required int keyLength,
}) {
  const message = 'pbkdf2-hmac-sha256';
  return compute(
    _deriveEntry,
    (password: password, salt: salt, iterations: iterations, keyLength: keyLength),
    debugLabel: message,
  );
}

/// Derivacion "de relleno" para igualar tiempos cuando el usuario no existe.
Future<void> burnTimingAsync({
  required int iterations,
  required int keyLength,
}) {
  return compute(
    _burnEntry,
    (password: 'timing-equalizer', salt: 'timing-equalizer', iterations: iterations, keyLength: keyLength),
    debugLabel: 'pbkdf2-hmac-sha256-burn',
  );
}

String _deriveEntry(
  ({String password, String salt, int iterations, int keyLength}) message,
) {
  return derive(
    password: message.password,
    salt: message.salt,
    iterations: message.iterations,
    keyLength: message.keyLength,
  );
}

String _burnEntry(
  ({String password, String salt, int iterations, int keyLength}) message,
) {
  derive(
    password: message.password,
    salt: message.salt,
    iterations: message.iterations,
    keyLength: message.keyLength,
  );
  return '';
}
