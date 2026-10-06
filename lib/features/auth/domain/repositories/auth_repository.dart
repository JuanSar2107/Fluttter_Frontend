import '../../../../core/errors/auth_failure.dart';
import '../entities/auth_session.dart';

/// Contrato de autenticacion.
///
/// La capa de presentacion depende **solo** de esta interfaz, nunca de
/// PBKDF2, `flutter_secure_storage` ni de ningun detalle de red.
///
/// ### Migracion a backend real
///
/// Cuando exista API, se anade `RemoteAuthDataSource` + se crea
/// `ApiAuthRepository implements AuthRepository`, y se cambia una sola linea en
/// `auth_providers.dart`. Ni las pantallas ni los providers cambian.
abstract interface class AuthRepository {
  /// Valida credenciales y persiste la sesion.
  ///
  /// Lanza [InvalidCredentialsFailure] si no coinciden,
  /// [TooManyAttemptsFailure] si la cuenta esta bloqueada y
  /// [SecureStorageFailure] si no se puede guardar la sesion.
  Future<AuthSession> signIn({
    required String username,
    required String password,
  });

  /// Recupera la sesion guardada, o `null` si no hay o esta expirada.
  ///
  /// Lanza [SecureStorageFailure] si el almacenamiento seguro falla.
  Future<AuthSession?> restoreSession();

  /// Elimina la sesion guardada.
  Future<void> signOut();
}
