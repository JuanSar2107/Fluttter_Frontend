import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/remote_category_data_source.dart';

final Provider<RemoteCategoryDataSource> categoryDataSourceProvider =
    Provider<RemoteCategoryDataSource>((ref) {
  return RemoteCategoryDataSource(ref.watch(apiClientProvider));
});

/// Proveedor que expone la lista de categorías disponibles desde el backend.
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final dataSource = ref.watch(categoryDataSourceProvider);
  return dataSource.getCategories();
});

/// Controlador para gestionar categorías en el backend (agregar/eliminar).
class CategoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Listo para operaciones
  }

  /// Agrega una nueva categoría en el backend.
  Future<bool> addCategory(String category) async {
    state = const AsyncLoading<void>();
    try {
      final dataSource = ref.read(categoryDataSourceProvider);
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

  /// Elimina una categoría en el backend.
  Future<bool> removeCategory(String category) async {
    state = const AsyncLoading<void>();
    try {
      final dataSource = ref.read(categoryDataSourceProvider);
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