import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:aviation_inventory/features/inventory/data/datasources/heavy_part_local_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('adds a heavy part and keeps it in local storage', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeAuthRepository(
      initialSession: FakeAuthRepository.validSession(),
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

    expect(find.text('Inventario de repuestos pesados'), findsOneWidget);
    await tester.tap(find.text('Añadir repuesto'));
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
    expect(find.text('Unidades en stock'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final preferences = await SharedPreferences.getInstance();
    final savedParts = HeavyPartLocalDataSource(preferences).loadParts();
    expect(savedParts, hasLength(1));
    expect(savedParts.single.partNumber, 'ENG-900');
    expect(savedParts.single.quantity, 2);
    expect(savedParts.single.location, 'Hangar A');
  });
}
