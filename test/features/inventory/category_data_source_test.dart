import 'package:aviation_inventory/features/inventory/data/datasources/category_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late CategoryDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    dataSource = CategoryDataSource(preferences);
  });

  test('incluye las categorias por defecto', () async {
    final categories = await dataSource.getCategories();

    expect(categories, contains('General'));
    expect(categories, contains('Motor'));
    expect(categories, hasLength(greaterThanOrEqualTo(9)));
  });

  test('agrega una categoria personalizada', () async {
    final added = await dataSource.addCategory('Frenos');
    final categories = await dataSource.getCategories();

    expect(added, isTrue);
    expect(categories, contains('Frenos'));
    expect(dataSource.isCustomCategory('Frenos'), isTrue);
  });

  test('rechaza duplicados ignorando mayusculas', () async {
    expect(await dataSource.addCategory('Frenos'), isTrue);
    expect(await dataSource.addCategory('frenos'), isFalse);
    expect(await dataSource.addCategory('  FRENOS '), isFalse);

    final categories = await dataSource.getCategories();
    expect(categories.where((c) => c.toLowerCase() == 'frenos'), hasLength(1));
  });

  test('rechaza duplicados contra categorias por defecto', () async {
    expect(await dataSource.addCategory('Motor'), isFalse);
  });

  test('no permite eliminar categorias por defecto', () async {
    expect(await dataSource.removeCategory('Motor'), isFalse);
    expect(await dataSource.getCategories(), contains('Motor'));
  });

  test('elimina categorias personalizadas', () async {
    await dataSource.addCategory('Frenos');

    expect(await dataSource.removeCategory('Frenos'), isTrue);
    expect(await dataSource.getCategories(), isNot(contains('Frenos')));
  });
}