import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_store.dart';
import '../../../../core/errors/auth_failure.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Almacenamiento seguro.
///
/// Sobrescribible en tests: `authRepositoryProvider.overrideWithValue(...)`.
final Provider<SecureStore> secureStoreProvider = Provider<SecureStore>(
  (ref) => SecureStore(),
);

final Provider<AuthLocalDataSource> authLocalDataSourceProvider =
    Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(ref.watch(secureStoreProvider)),
);

/// Configuracion de sesion.
final Provider<SessionConfig> sessionConfigProvider = Provider<SessionConfig>(
  (ref) => const SessionConfig(ttl: Duration(hours: 8)),
);

/// Repositorio de autenticacion.
///
/// ### Cuando exista backend
///
/// Sustituye la implementacion de esta sola linea:
///
/// ```dart
/// final authRepositoryProvider = Provider<AuthRepository>((ref) {
///   return RemoteAuthRepository(client: ref.watch(apiClientProvider));
/// });
/// ```
///
/// Ni las pantallas ni el controlador cambian, porque ambos dependen de la
/// interfaz `AuthRepository`.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    sessionConfig: ref.watch(sessionConfigProvider),
  ),
);

/// Estado de sesion, autoritativo para toda la app.
///
/// * `AsyncLoading` -> restaurando la sesion guardada (mostrar splash).
/// * `AsyncError`   -> fallo al leer el almacenamiento.
/// * `AsyncData(null)` -> no hay sesion (mostrar login).
/// * `AsyncData(sesion)` -> autenticado.
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  /// Intenta iniciar sesion.
  ///
  /// **No** cambia el estado global a `AsyncError` cuando falla: el estado
  /// global representa "hay sesion o no", no "el ultimo intento funciono". El
  /// fallo se devuelve al caller para que lo muestre junto al formulario.
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);

    final session = await repository.signIn(
      username: username,
      password: password,
    );

    state = AsyncData<AuthSession?>(session);
    return session;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData<AuthSession?>(null);
  }

  /// Reintenta la lectura de la sesion guardada.
  Future<void> retry() async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).restoreSession(),
    );
  }
}

final AsyncNotifierProvider<AuthController, AuthSession?> authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(
  AuthController.new,
);

/// Sesion actual, o `null` si no hay.
final Provider<AuthSession?> currentSessionProvider = Provider<AuthSession?>(
  (ref) => ref.watch(authControllerProvider).value,
);

/// Usuario actual, o `null` si no hay sesion.
final Provider<AppUser?> currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(currentSessionProvider)?.user,
);

/// `true` si hay una sesion vigente.
final Provider<bool> isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(currentSessionProvider) != null,
);

/// `true` si el almacenamiento seguro del SO no esta disponible.
///
/// Permite avisar al usuario de que la sesion no sobrevivira a un reinicio.
final Provider<bool> isStorageDegradedProvider = Provider<bool>((ref) {
  return ref.watch(authLocalDataSourceProvider).isDegraded;
});

/// Traduce un error de autenticacion a un mensaje apto para la UI.
String describeAuthError(Object error) {
  if (error is AuthFailure) return error.message;
  return const UnexpectedAuthFailure().message;
}
