import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import 'mock_credential_store.dart';

/// Persistencia local de la sesion.
///
/// Guarda el token en almacenamiento seguro del sistema operativo (Keychain en
/// iOS/macOS, Keystore cifrado en Android, WebCrypto en web). Nunca guarda la
/// contrasena.
///
/// Cuando exista backend, este archivo se conserva tal cual: la sesion es un
/// concepto local, no remoto.
class AuthLocalDataSource {
  AuthLocalDataSource(this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SecureStore _store;

  /// Reloj inyectable para poder simular el paso del tiempo en tests.
  final DateTime Function() _clock;

  static const String _tokenKey = 'aero_parts.session.token';
  static const String _userIdKey = 'aero_parts.session.user_id';
  static const String _usernameKey = 'aero_parts.session.username';
  static const String _displayNameKey = 'aero_parts.session.display_name';
  static const String _roleKey = 'aero_parts.session.role';
  static const String _issuedAtKey = 'aero_parts.session.issued_at';
  static const String _expiresAtKey = 'aero_parts.session.expires_at';

  Future<void> saveSession(AuthSession session) async {
    await _store.write(_tokenKey, session.token);
    await _store.write(_userIdKey, session.user.id);
    await _store.write(_usernameKey, session.user.username);
    await _store.write(_displayNameKey, session.user.displayName);
    await _store.write(_roleKey, session.user.role.name);
    await _store.write(_issuedAtKey, session.issuedAt.toIso8601String());
    await _store.write(_expiresAtKey, session.expiresAt.toIso8601String());
  }

  /// Lee la sesion guardada. Devuelve `null` si falta, esta corrupta o expiro.
  ///
  /// Una sesion corrupta o expirada se **borra**: dejarla acumulada haria que
  /// cada arranque reintentara leerla y complicaria el diagnostico.
  Future<AuthSession?> readSession() async {
    final token = await _store.read(_tokenKey);
    final userId = await _store.read(_userIdKey);
    final username = await _store.read(_usernameKey);
    final displayName = await _store.read(_displayNameKey);
    final roleName = await _store.read(_roleKey);
    final issuedAtRaw = await _store.read(_issuedAtKey);
    final expiresAtRaw = await _store.read(_expiresAtKey);

    if (token == null ||
        userId == null ||
        username == null ||
        displayName == null ||
        roleName == null ||
        issuedAtRaw == null ||
        expiresAtRaw == null) {
      return null;
    }

    final issuedAt = DateTime.tryParse(issuedAtRaw);
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    final role = UserRole.values.where((value) => value.name == roleName);

    if (issuedAt == null || expiresAt == null || role.isEmpty) {
      await clearSession();
      return null;
    }

    final session = AuthSession(
      token: token,
      user: AppUser(
        id: userId,
        username: username,
        displayName: displayName,
        role: role.first,
      ),
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );

    if (session.isExpiredAt(_clock())) {
      await clearSession();
      return null;
    }

    return session;
  }

  Future<void> clearSession() => _store.deleteAll(const [
        _tokenKey,
        _userIdKey,
        _usernameKey,
        _displayNameKey,
        _roleKey,
        _issuedAtKey,
        _expiresAtKey,
      ]);

  /// `true` si el almacenamiento seguro del SO no esta disponible y estamos
  /// usando el respaldo en memoria.
  bool get isDegraded => _store.isFallbackActive;

  /// Busca un usuario por nombre (normalizado en minusculas).
  ///
  /// En una demo solo mira la lista local. Con backend, esto desaparece y la
  /// comparacion ocurre en el servidor.
  MockCredential? findByUsername(String normalizedUsername) {
    for (final credential in MockCredential.all) {
      if (credential.username.toLowerCase() == normalizedUsername) {
        return credential;
      }
    }
    return null;
  }
}
