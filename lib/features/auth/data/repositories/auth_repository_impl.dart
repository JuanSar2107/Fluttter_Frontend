import '../../../../core/errors/auth_failure.dart';
import '../../../../core/security/hash_runner.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/mock_credential_store.dart';

/// Implementacion local de [AuthRepository].
///
/// ## Simula una red
///
/// Hay un `Future.delayed` de ~450 ms antes de validar. Sin esto el login
/// responderia en un milisegundo y la UI no se veria nunca en estado de carga,
/// lo que oculta errores de maquetado que si apareceran con una API real.
///
/// ## Limite de intentos
///
/// Tras [maxAttempts] fallos consecutivos la cuenta se bloquea temporalmente.
///
/// **Esto no es una defensa real.** El contador vive en memoria: reiniciar la
/// app lo pone a cero, y quien tenga el binario puede evitar el login por
/// completo. Su unico proposito es una red de seguridad para usuarios que
/// escriben mal su contrasena. El bloqueo real de fuerza bruta tiene que
/// vivir en el servidor.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required AuthLocalDataSource localDataSource,
    this.sessionConfig = const SessionConfig(),
    this.networkLatency = const Duration(milliseconds: 450),
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _local = localDataSource,
        _clock = clock ?? DateTime.now;

  final AuthLocalDataSource _local;
  final DateTime Function() _clock;

  /// Tiempo de vida de la sesion creada.
  final SessionConfig sessionConfig;

  /// Simula la latencia de una peticion de red.
  final Duration networkLatency;

  /// Intentos fallidos antes de bloquear.
  final int maxAttempts;

  /// Duracion del bloqueo.
  final Duration lockoutDuration;

  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  /// Bloquea el envio de la contrasena en texto plano por HTTPS sin validarlo.
  ///
  /// En esta demo no hay red, asi que no aplica. Cuando exista backend, el
  /// cliente debe rechazar cualquier URL que no sea HTTPS para no enviar
  /// credenciales en claro.
  static bool isSecureEndpoint(Uri uri) => uri.scheme == 'https';

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();

    await Future<void>.delayed(networkLatency);

    _throwIfLockedOut();

    if (normalized.isEmpty || password.isEmpty) {
      _registerFailure();
      throw const InvalidCredentialsFailure();
    }

    final credential = _local.findByUsername(normalized);

    if (credential == null) {
      // Deriva un hash de relleno para que el tiempo de respuesta no revele
      // si el usuario existe o no (enumeracion de cuentas por timing).
      await burnTimingAsync(
        iterations: credential?.iterations ?? MockCredential.admin.iterations,
        keyLength: MockCredential.admin.keyLength,
      );
      _registerFailure();
      throw const InvalidCredentialsFailure();
    }

    final derived = await deriveHashAsync(
      password: password,
      salt: credential.salt,
      iterations: credential.iterations,
      keyLength: credential.keyLength,
    );

    if (derived != credential.passwordHash) {
      _registerFailure();
      throw const InvalidCredentialsFailure();
    }

    _failedAttempts = 0;
    _lockedUntil = null;

    final now = _clock();
    final session = AuthSession(
      token: generateOpaqueToken(),
      user: AppUser(
        id: normalized,
        username: credential.username,
        displayName: credential.displayName,
        role: credential.role,
      ),
      issuedAt: now,
      expiresAt: now.add(sessionConfig.ttl),
    );

    await _local.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final session = await _local.readSession();
      // Doble comprobacion con el reloj del repositorio: el data source usa el
      // suyo, y aqui nos aseguramos de que ambos coincidan.
      if (session != null && session.isExpiredAt(_clock())) {
        await _local.clearSession();
        return null;
      }
      return session;
    } on AuthFailure {
      rethrow;
    } catch (error) {
      throw SecureStorageFailure(
        'No se pudo leer la sesion guardada. Vuelve a entrar.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _failedAttempts = 0;
    _lockedUntil = null;
    await _local.clearSession();
  }

  void _registerFailure() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = _clock().add(lockoutDuration);
    }
  }

  void _throwIfLockedOut() {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return;

    final now = _clock();
    if (now.isBefore(lockedUntil)) {
      throw TooManyAttemptsFailure(
        lockedUntil.difference(now).inSeconds.clamp(1, 86400),
      );
    }

    // Bloqueo vencido: se reinicia el contador.
    _lockedUntil = null;
    _failedAttempts = 0;
  }
}

/// Repositorio de respaldo: sin almacenamiento local.
///
/// Permite ejecutar la app en tests sin `flutter_secure_storage`.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({
    this.sessionConfig = const SessionConfig(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Tiempo de vida de la sesion creada.
  final SessionConfig sessionConfig;

  final DateTime Function() _clock;

  AuthSession? _session;

  AuthSession? get currentSession => _session;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final credential = MockCredential.all.firstWhere(
      (c) => c.username.toLowerCase() == normalized,
      orElse: () => throw const InvalidCredentialsFailure(),
    );

    // Reutiliza los parametros reales de la credencial (salt, iteraciones y
    // longitud), en vez de asume que todos los usuarios comparten parametros.
    if (!constantTimeEquals(
      derive(
        password: password,
        salt: credential.salt,
        iterations: credential.iterations,
        keyLength: credential.keyLength,
      ),
      credential.passwordHash,
    )) {
      throw const InvalidCredentialsFailure();
    }

    final now = _clock();
    final session = AuthSession(
      token: generateOpaqueToken(),
      user: AppUser(
        id: normalized,
        username: credential.username,
        displayName: credential.displayName,
        role: credential.role,
      ),
      issuedAt: now,
      expiresAt: now.add(sessionConfig.ttl),
    );
    _session = session;
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<void> signOut() async => _session = null;
}
