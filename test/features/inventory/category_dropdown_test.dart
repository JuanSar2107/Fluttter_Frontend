import 'package:aviation_inventory/app.dart';
import 'package:aviation_inventory/features/auth/domain/entities/app_user.dart';
import 'package:aviation_inventory/features/auth/domain/entities/auth_session.dart';
import 'package:aviation_inventory/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';

AuthSession _sessionFor(UserRole role) {
  final now = DateTime.now();
  return AuthSession(
    token: 'test-token',
    user: AppUser(
      id: 'user',
      username: 'user',
      displayName: 'Usuario de Prueba',
      role: role,
    ),
    issuedAt: now,
    expiresAt: now.add(const Duration(hours: 8)),
  );
}

Future<void> _pumpDashboard(WidgetTester tester, UserRole role) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repository = FakeAuthRepository(initialSession: _sessionFor(role));
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

  await tester.tap(find.text('Añadir repuesto'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un admin ve la opcion de agregar nueva categoria', (
    tester,
  ) async {
    await _pumpDashboard(tester, UserRole.admin);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Agregar nueva categoría...'), findsOneWidget);
  });

  testWidgets('un usuario de consulta no ve la opcion de agregar categoria', (
    tester,
  ) async {
    await _pumpDashboard(tester, UserRole.viewer);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Agregar nueva categoría...'), findsNothing);
  });

  testWidgets('el admin crea una categoria y queda seleccionada', (
    tester,
  ) async {
    await _pumpDashboard(tester, UserRole.admin);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar nueva categoría...'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva categoría'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de la categoría'),
      'Frenos',
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    // La categoria creada queda seleccionada en el campo.
    expect(find.text('Frenos'), findsWidgets);
  });
}