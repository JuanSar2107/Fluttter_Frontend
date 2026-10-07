import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/core/errors/auth_failure.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:aviation_inventory/features/auth/presentation/screens/login_screen.dart';
import 'package:aviation_inventory/features/auth/presentation/screens/session_error_screen.dart';
import 'package:aviation_inventory/features/auth/presentation/screens/splash_screen.dart';
import 'package:aviation_inventory/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  // El dashboard persiste el inventario en SharedPreferences; sin este mock
  // `getInstance()` se queda esperando en los tests y `pumpAndSettle` expira.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Monta la app completa con un repositorio controlado.
  Future<FakeAuthRepository> pumpApp(
    WidgetTester tester, {
    FakeAuthRepository? repository,
  }) async {
    final repo = repository ?? FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AeroPartsApp(),
      ),
    );
    return repo;
  }

  group('arranque sin sesion', () {
    testWidgets('muestra el splash y luego el login', (tester) async {
      await pumpApp(tester);

      // El splash aparece mientras `restoreSession` resuelve.
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('el login muestra los campos y el boton', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contrasena'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });

  group('arranque con sesion previa', () {
    testWidgets('va directo al home sin pasar por el login',
        (tester) async {
      await pumpApp(
        tester,
        repository: FakeAuthRepository(
          initialSession: FakeAuthRepository.validSession(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('fallo al restaurar la sesion', () {
    testWidgets('muestra la pantalla de error con opcion de reintentar',
        (tester) async {
      final repository = FakeAuthRepository()..storageThrows = true;

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.byType(SessionErrorScreen), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Entrar de todos modos'), findsOneWidget);
    });

    testWidgets('reintentar con el almacenamiento recuperado entra al home',
        (tester) async {
      final repository = FakeAuthRepository()..storageThrows = true;

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();
      expect(find.byType(SessionErrorScreen), findsOneWidget);

      repository
        ..storageThrows = false
        ..failWith = null;

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('validacion del formulario', () {
    testWidgets('no envia si los campos estan vacios', (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 0);
      expect(find.text('Ingresa tu usuario.'), findsOneWidget);
      expect(find.text('Ingresa tu contrasena.'), findsOneWidget);
    });

    testWidgets('rechaza un usuario demasiado corto', (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'ab',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'contrasena123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 0);
      expect(
        find.text('El usuario debe tener al menos 3 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('rechaza caracteres no permitidos en el usuario',
        (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin@correo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'contrasena123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 0);
      expect(
        find.text('Solo letras, digitos, punto, guion y guion bajo.'),
        findsOneWidget,
      );
    });

    testWidgets('rechaza una contrasena corta', (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Contrasena'), 'corta');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 0);
      expect(
        find.text('La contrasena debe tener al menos 8 caracteres.'),
        findsOneWidget,
      );
    });
  });

  group('inicio de sesion correcto', () {
    testWidgets('navega al home y muestra los datos del usuario',
        (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'Aero#Parts-2026!',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
      // El rol viene del repositorio fake y se muestra en la badge del panel.
      expect(find.text('Administrador'), findsWidgets);
      expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
    });

    testWidgets('solo llama a signIn una vez por envio', (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'Aero#Parts-2026!',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 1);
    });

    testWidgets('pulsa Enter en el campo contrasena envia el formulario',
        (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'Aero#Parts-2026!',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 1);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('inicio de sesion fallido', () {
    testWidgets('muestra el mensaje de error junto al formulario',
        (tester) async {
      await pumpApp(
        tester,
        repository: FakeAuthRepository(failWith: const InvalidCredentialsFailure()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'incorrecta',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Usuario o contrasena incorrectos.'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('muestra el tiempo de espera si la cuenta esta bloqueada',
        (tester) async {
      await pumpApp(
        tester,
        repository: FakeAuthRepository(
          failWith: TooManyAttemptsFailure(45),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'incorrecta',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Demasiados intentos fallidos'),
        findsOneWidget,
      );
      expect(find.textContaining('45 s'), findsOneWidget);
    });

    testWidgets('un error inesperado produce un mensaje generico',
        (tester) async {
      await pumpApp(
        tester,
        repository: FakeAuthRepository(failWith: StateError('fallo interno')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'incorrecta',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      // No se filtra el detalle interno del error.
      expect(find.textContaining('fallo interno'), findsNothing);
      expect(
        find.text('Ocurrio un error inesperado. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('el error se limpia al reintentar', (tester) async {
      final repository = FakeAuthRepository(
        failWith: const InvalidCredentialsFailure(),
      );
      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'incorrecta',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Usuario o contrasena incorrectos.'), findsOneWidget);

      repository.failWith = null;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'Aero#Parts-2026!',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Usuario o contrasena incorrectos.'), findsNothing);
    });
  });

  group('cambio de visibilidad de la contrasena', () {
    testWidgets('el campo alterna entre ofuscado y visible', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      TextField passwordField() => tester.widget<TextField>(
            find.descendant(
              of: find.byType(Form),
              matching: find.byType(TextField),
            ).last,
          );

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(passwordField().obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(passwordField().obscureText, isTrue);
    });
  });

  group('cerrar sesion', () {
    testWidgets('vuelve al login y limpia el estado', (tester) async {
      final repository = await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contrasena'),
        'Aero#Parts-2026!',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(repository.signOutCalls, 1);

      // Y una recarga no restaura la sesion.
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      expect(await container.read(authRepositoryProvider).restoreSession(), isNull);
    });
  });
}
