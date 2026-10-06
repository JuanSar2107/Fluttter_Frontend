/// Fuente de credenciales **de mentira**, para desarrollo.
///
/// ESTO NO ES AUTENTICACION REAL. Lee [README] en la raiz del proyecto.
///
/// ## Lo que hay aqui
///
/// Un hash PBKDF2-HMAC-SHA256 con salt, generado por `tool/hash_password.dart`.
///
/// ## Lo que NO hay aqui
///
/// La contrasena. Jamas se escribe en el codigo.
///
/// ## Por que esto no es seguro (y por que es aceptable en una demo)
///
/// Un atacante que descargue el APK puede:
///
/// 1. Leer estas constantes.
/// 2. Verificar cualquier contrasena contra ellas sin limite de intentos,
///    porque el `AttemptLimiter` vive en memoria y puede simplemente evitarse.
/// 3. Reemplazar el APK por uno que acepte cualquier clave.
///
/// Por eso la unica defensa real es que **la verificacion ocurra en un
/// servidor** al que el cliente no pueda saltarse. Cuando exista backend, borra
/// este archivo y usa `RemoteAuthRepository`.
///
/// Para desarrollo local esto es comodo y no tiene coste. Para produccion, nunca.
///
/// Generado con: `dart run tool/hash_password.dart`
/// Contrasea de la demo: `Aero#Parts-2026!`
library;

import '../../domain/entities/app_user.dart';

/// Credenciales del usuario de prueba.
///
/// ### Para cambiar la contrasena
///
/// 1. `dart run tool/hash_password.dart` (pega la nueva contrasena).
/// 2. Reemplaza `salt` y `passwordHash` por los valores impresos.
/// 3. `flutter test` para confirmar que el login sigue funcionando.
class MockCredential {
  const MockCredential({
    required this.username,
    required this.displayName,
    required this.role,
    required this.salt,
    required this.passwordHash,
    required this.iterations,
    required this.keyLength,
  });

  final String username;
  final String displayName;
  final UserRole role;

  /// Salt aleatorio en base64url (16 bytes).
  final String salt;

  /// PBKDF2-HMAC-SHA256 en base64url (32 bytes). No es la contrasena.
  final String passwordHash;

  final int iterations;
  final int keyLength;

  static const String algorithm = 'pbkdf2-hmac-sha256';

  static const MockCredential admin = MockCredential(
    username: 'admin',
    displayName: 'Administrador',
    role: UserRole.admin,
    salt: 'z0xye-vQbxexaCXjU0sMJg==',
    passwordHash: '0Fvi0iog_df-kxltEwNmWk2DhNRlrQz-K9usdccPYy4=',
    iterations: 12000,
    keyLength: 32,
  );

  static const List<MockCredential> all = [admin];
}
