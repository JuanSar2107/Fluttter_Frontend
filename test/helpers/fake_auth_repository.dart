import 'package:aviation_inventory/core/errors/auth_failure.dart';
import 'package:aviation_inventory/features/auth/domain/entities/app_user.dart';
import 'package:aviation_inventory/features/auth/domain/entities/auth_session.dart';
import 'package:aviation_inventory/features/auth/domain/repositories/auth_repository.dart';

/// Repositorio controlado para tests.
///
/// Permite simular cualquier escenario sin tocar disco ni isolates: sesion
/// existente, ausencia de sesion, errores de almacenamiento y cuelgues.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSession? initialSession,
    this.failWith,
    this.storageThrows = false,
  }) : _session = initialSession;

  AuthSession? _session;

  /// Si no es null, [signIn] lanza este error.
  Object? failWith;

  /// Si es `true`, [restoreSession] lanza, simulando almacenamiento roto.
  bool storageThrows;

  /// Numero de llamadas a [signIn]. Permite verificar que el doble toque no
  /// genera dos peticiones.
  int signInCalls = 0;

  int signOutCalls = 0;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    signInCalls++;

    final failure = failWith;
    if (failure != null) throw failure;

    final now = DateTime.now();
    final session = AuthSession(
      token: 'test-token$signInCalls',
      user: AppUser(
        id: username.trim().toLowerCase(),
        username: username.trim(),
        displayName: 'Usuario de Prueba',
        role: UserRole.admin,
      ),
      issuedAt: now,
      expiresAt: now.add(const Duration(hours: 8)),
    );

    _session = session;
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (storageThrows) {
      throw const SecureStorageFailure('Almacenamiento no disponible.');
    }
    final session = _session;
    if (session == null || session.isExpired) return null;
    return session;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _session = null;
  }

  /// Sesion valida de partida, con expiracion lejana.
  static AuthSession validSession({Duration ttl = const Duration(hours: 8)}) {
    final now = DateTime.now();
    return AuthSession(
      token: 'existing-token',
      user: const AppUser(
        id: 'admin',
        username: 'admin',
        displayName: 'Administrador',
        role: UserRole.admin,
      ),
      issuedAt: now,
      expiresAt: now.add(ttl),
    );
  }
}
