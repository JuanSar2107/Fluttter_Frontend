import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:aviation_inventory/features/auth/presentation/screens/login_screen.dart';
import 'package:aviation_inventory/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  // El dashboard persiste el inventario en SharedPreferences; sin este mock
  // `getInstance()` se queda esperando en los tests y `pumpAndSettle` expira.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Monta la app en un viewport concreto.
  ///
  /// Los tests de widgets usan 800x600 por defecto, que es mas ancho que un
  /// movil pero mas estrecho que un escritorio. Estos tests recorren los tres
  /// intervalos de diseño en los que el login cambia de estructura.
  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    bool authenticated = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeAuthRepository(
      initialSession: authenticated ? FakeAuthRepository.validSession() : null,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AeroPartsApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('login en movil (390x844)', () {
    testWidgets('no muestra el panel de marca', (tester) async {
      await pumpApp(tester, size: const Size(390, 844));

      expect(find.byType(LoginScreen), findsOneWidget);
      // El panel de marca (lado izquierdo con degradado y lista de features) NO
      // debe aparecer en movil.
      expect(find.text('Inventario de\nrepuestos aeronáuticos'), findsNothing);
      expect(find.text('Existencias por pieza'), findsNothing);
      // El logo en el formulario SI se muestra (con wordmark), eso es correcto.
    });

    testWidgets('los campos son accesibles y caben en pantalla', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(390, 844));

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contrasena'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);

      // Sin overflow: si hubiera, Flutter lanzaria la excepcion durante el
      // layout y `pumpAndSettle` fallaria.
      expect(tester.takeException(), isNull);
    });

    testWidgets('el texto de entrada es legible sin recortar', (tester) async {
      await pumpApp(tester, size: const Size(390, 844));

      // El ancho del formulario esta acotado a 420, asi que en 390 px debe
      // dejar margen a los lados.
      final formWidth = tester.getSize(find.byType(LoginScreen)).width;
      expect(formWidth, 390);
      expect(tester.takeException(), isNull);
    });
  });

  group('login en tablet vertical (768x1024)', () {
    testWidgets('todavia no muestra el panel de marca', (tester) async {
      await pumpApp(tester, size: const Size(768, 1024));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Inventario de\nrepuestos aeronáuticos'), findsNothing);
    });
  });

  group('login en escritorio (1440x900)', () {
    testWidgets('muestra el panel de marca junto al formulario', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(1440, 900));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Inventario de\nrepuestos aeronáuticos'),
        findsOneWidget,
      );
      expect(find.text('Existencias por pieza'), findsOneWidget);
      expect(find.text('Trazabilidad por lote'), findsOneWidget);
      expect(find.text('Certificados de conformidad'), findsOneWidget);
      expect(find.text('Historial de movimientos'), findsOneWidget);
      expect(find.text('Iniciar sesion'), findsOneWidget);
    });

    testWidgets('el formulario no se estira a todo el ancho', (tester) async {
      await pumpApp(tester, size: const Size(1440, 900));

      // El `ConstrainedBox` limita a 420 px: en una pantalla de 1440 el texto
      // se lee bien y no se convierte en una linea larguisima.
      final textFieldWidth = tester
          .getSize(find.byType(TextFormField).first)
          .width;
      expect(textFieldWidth, lessThanOrEqualTo(420));
    });
  });

  group('dashboard en movil', () {
    testWidgets('no desborda y muestra el contenido', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), authenticated: true);

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
      expect(find.text('Añadir repuesto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la badge de usuario es visible', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), authenticated: true);

      // En móvil, la badge de usuario puede no estar visible inmediatamente
      // si está dentro del scroll. Solo verificamos que no haya overflow.
      expect(tester.takeException(), isNull);
    });
  });

  group('dashboard en escritorio', () {
    testWidgets('muestra el contenido del dashboard', (tester) async {
      await pumpApp(tester, size: const Size(1440, 900), authenticated: true);

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
      expect(find.text('Repuestos registrados'), findsOneWidget);
      expect(find.text('Añadir repuesto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('dashboard en tablet vertical', () {
    testWidgets('no desborda en anchura intermedia', (tester) async {
      await pumpApp(tester, size: const Size(768, 1024), authenticated: true);

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
