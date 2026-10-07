import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/category_data_source.dart';

final FutureProvider<CategoryDataSource> categoryDataSourceProvider =
    FutureProvider<CategoryDataSource>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  return CategoryDataSource(preferences);
});

/// Proveedor que expone la lista de categorías disponibles.
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final dataSource = await ref.watch(categoryDataSourceProvider.future);
  return dataSource.getCategories();
});

/// Controlador para gestionar categorías (agregar/eliminar).
class CategoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Nada que hacer aquí, solo necesitamos el estado async para las operaciones
  }

  /// Agrega una nueva categoría.
  Future<bool> addCategory(String category) async {
    state = const AsyncLoading<void>();
    try {
      final dataSource = await ref.read(categoryDataSourceProvider.future);
      final result = await dataSource.addCategory(category);
      if (result) {
        ref.invalidate(categoriesProvider);
      }
      state = const AsyncData<void>(null);
      return result;
    } catch (error) {
      state = AsyncError<void>(error, StackTrace.current);
      return false;
    }
  }

  /// Elimina una categoría personalizada.
  Future<bool> removeCategory(String category) async {
    state = const AsyncLoading<void>();
    try {
      final dataSource = await ref.read(categoryDataSourceProvider.future);
      final result = await dataSource.removeCategory(category);
      if (result) {
        ref.invalidate(categoriesProvider);
      }
      state = const AsyncData<void>(null);
      return result;
    } catch (error) {
      state = AsyncError<void>(error, StackTrace.current);
      return false;
    }
  }
}

final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, void>(CategoryController.new);