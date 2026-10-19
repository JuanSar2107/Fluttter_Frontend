import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:aviation_inventory/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_inventory.dart';

void main() {
  Future<FakeHeavyPartDataSource> pumpDashboard(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    FakeHeavyPartDataSource? dataSource,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final source =
        dataSource ??
        FakeHeavyPartDataSource([
          samplePart(),
          samplePart(
            id: '2',
            partNumber: 'PMP-FUEL-737',
            description: 'Bomba combustible',
            location: 'Hangar 1',
            quantity: 1,
          ),
        ]);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialSession: FakeAuthRepository.validSession()),
        ),
        ...inventoryOverrides(source),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AeroPartsApp(),
      ),
    );
    await tester.pumpAndSettle();
    return source;
  }

  testWidgets('añade un repuesto y aparece en la tabla', (tester) async {
    final source = await pumpDashboard(tester);

    await tester.tap(find.text('Añadir nuevo repuesto'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número de parte'),
      'ENG-900',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'Motor auxiliar',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Cantidad'), '2');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ubicación'),
      'Hangar A',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('ENG-900'), findsOneWidget);
    expect(find.text('Motor auxiliar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final saved = source.parts.singleWhere((p) => p.partNumber == 'ENG-900');
    expect(saved.quantity, 2);
    expect(saved.location, 'Hangar A');
  });

  testWidgets('la busqueda filtra las filas', (tester) async {
    await pumpDashboard(tester);
    expect(find.text('CYL-HEAD-A2'), findsOneWidget);
    expect(find.text('PMP-FUEL-737'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(DashboardScreen),
        matching: find.byType(TextField),
      ),
      'bomba',
    );
    await tester.pumpAndSettle();

    expect(find.text('CYL-HEAD-A2'), findsNothing);
    expect(find.text('PMP-FUEL-737'), findsOneWidget);
  });

  testWidgets('abre el panel de detalle al pulsar una fila', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('CYL-HEAD-A2'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del Componente'), findsOneWidget);
    expect(find.text('Historial de movimientos'), findsOneWidget);
    expect(find.text('Sin movimientos registrados.'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar detalle'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del Componente'), findsNothing);
  });

  testWidgets('elimina un repuesto tras confirmar', (tester) async {
    final source = await pumpDashboard(tester);

    await tester.tap(find.byTooltip('Eliminar PMP-FUEL-737'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('PMP-FUEL-737'), findsNothing);
    expect(source.parts.map((p) => p.partNumber), ['CYL-HEAD-A2']);
  });

  testWidgets('en movil muestra tarjetas sin desbordar', (tester) async {
    await pumpDashboard(tester, size: const Size(390, 844));

    expect(find.text('CYL-HEAD-A2'), findsOneWidget);
    expect(find.text('Part #'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('estado derivado', () {
    test('critico cuando la existencia no supera el minimo', () {
      expect(
        PartStatus.of(samplePart(quantity: 5, minStock: 5)),
        PartStatus.critical,
      );
      expect(
        PartStatus.of(samplePart(condition: 'No disponible')),
        PartStatus.critical,
      );
    });

    test('stock bajo hasta el doble del minimo', () {
      expect(
        PartStatus.of(samplePart(quantity: 10, minStock: 5)),
        PartStatus.low,
      );
      expect(
        PartStatus.of(samplePart(quantity: 11, minStock: 5)),
        PartStatus.available,
      );
    });

    test('inspeccion respeta la condicion registrada', () {
      expect(
        PartStatus.of(samplePart(condition: 'En inspección')),
        PartStatus.inspection,
      );
    });
  });

  test('el CSV escapa comillas y lleva cabecera', () {
    final csv = buildInventoryCsv([
      samplePart(description: 'Válvula "A"'),
    ]);
    final lines = csv.split('\r\n');
    expect(lines, hasLength(2));
    expect(lines.first, startsWith('"Part #","Nombre"'));
    expect(lines.last, contains('"Válvula ""A"""'));
  });
}
