import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/auth_failure.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/session_error_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';

/// Rutas de la aplicacion.
///
/// Se centralizan aqui como strings para no repetir literales.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';

  /// Ruta de error al restaurar la sesion.
  ///
  /// Vive fuera de [AppRoutes] a proposito: es una pantalla de fallo, no un
  /// destino de navegacion, y asi se distingue de las rutas de producto.
  static const String sessionError = '/session-error';
}

const String kSessionErrorRoute = AppRoutes.sessionError;

/// Router declarativo con redireccion segun el estado de sesion.
///
/// ## Por que `redirect` y no condicionales en `build`
///
/// La redireccion declarativa garantiza que **es imposible** navegar a una
/// pantalla protegida sin sesion: incluso con un boton de retroceso o un deep
/// link, `redirect` se reevalua antes de construir la ruta.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // `refreshListenable` hace que go_router vuelva a evaluar `redirect`
    // cuando cambia el estado de autenticacion.
    refreshListenable: _RouterRefresh(ref),

    redirect: (context, state) {
      final location = state.matchedLocation;

      return switch (ref.read(authControllerProvider)) {
        // Aun leyendo el almacenamiento: el splash no es un destino, solo una
        // espera. Cualquier otra ruta debe esperar tambien.
        AsyncLoading() =>
          location == AppRoutes.splash ? null : AppRoutes.splash,

        // Error al leer la sesion: ir a la pantalla de error, sin loop.
        AsyncError() =>
          location == kSessionErrorRoute ? null : kSessionErrorRoute,

        // Sin sesion: todo excepto el splash conduce al login.
        AsyncData(value: null) =>
          location == AppRoutes.login ? null : AppRoutes.login,

        // Con sesion: el splash y el login ya cumplieron su funcion, asi que
        // se redirige. Sin esta rama, un usuario con sesion restaurada se
        // quedaria atrapado viendo "Restaurando sesion..." para siempre.
        AsyncData() => switch (location) {
            AppRoutes.dashboard => null,
            AppRoutes.inventory => null,
            _ => AppRoutes.dashboard,
          },
      };
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: kSessionErrorRoute,
        builder: (context, state) => SessionErrorScreen(
          // `extra` no viene de una navegacion nuestra: puede ser null si se
          // restauro la sesion con un error ya envuelto.
          error: state.extra ?? const SecureStorageFailure(),
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ruta no encontrada: ${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  ),
);

/// Adapta los cambios de `authControllerProvider` al `Listenable` que espera
/// go_router.
///
/// Se apoya en un `StreamSubscription` porque `AsyncNotifier` no es un
/// `ValueListenable`.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _subscription = _ref.listen<AsyncValue<Object?>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
      // `fireImmediately` cubre el estado ya resuelto antes de suscribirse.
      fireImmediately: true,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<Object?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
