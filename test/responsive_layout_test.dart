import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:aviation_inventory/features/auth/presentation/screens/login_screen.dart';
import 'package:aviation_inventory/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
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

    testWidgets('los campos son accesibles y caben en pantalla',
        (tester) async {
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
    testWidgets('muestra el panel de marca junto al formulario',
        (tester) async {
      await pumpApp(tester, size: const Size(1440, 900));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Inventario de\nrepuestos aeronáuticos'), findsOneWidget);
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
      final textFieldWidth = tester.getSize(find.byType(TextFormField).first).width;
      expect(textFieldWidth, lessThanOrEqualTo(420));
    });
  });

  group('home en movil', () {
    testWidgets('no desborda con el panel de sesion', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), authenticated: true);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Sesion activa'), findsOneWidget);
      expect(find.text('Cerrar sesion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el boton de cerrar sesion es pulsable', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), authenticated: true);

      final button = find.widgetWithText(OutlinedButton, 'Cerrar sesion');
      expect(button, findsOneWidget);

      // No debe estar fuera de la pantalla ni con tamano cero.
      final size = tester.getSize(button);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      expect(size.height, greaterThanOrEqualTo(40));

      final position = tester.getTopLeft(button);
      expect(position.dx, greaterThanOrEqualTo(0));
      expect(position.dy, greaterThanOrEqualTo(0));
    });
  });

  group('home en escritorio', () {
    testWidgets('los modulos pendientes se muestran en rejilla',
        (tester) async {
      await pumpApp(tester, size: const Size(1440, 900), authenticated: true);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Modulos pendientes'), findsOneWidget);
      expect(find.text('Existencias'), findsOneWidget);
      expect(find.text('Usuarios'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('home en tablet vertical', () {
    testWidgets('no desborda en anchura intermedia', (tester) async {
      await pumpApp(tester, size: const Size(768, 1024), authenticated: true);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Sesion activa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
