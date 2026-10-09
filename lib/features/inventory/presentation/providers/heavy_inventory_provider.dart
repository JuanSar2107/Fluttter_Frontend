import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/remote_heavy_part_data_source.dart';
import '../../domain/entities/heavy_part.dart';
import 'category_provider.dart';

final Provider<RemoteHeavyPartDataSource> heavyPartDataSourceProvider =
    Provider<RemoteHeavyPartDataSource>((ref) {
  return RemoteHeavyPartDataSource(
    apiClient: ref.watch(apiClientProvider),
    categoryDataSource: ref.watch(categoryDataSourceProvider),
  );
});

final AsyncNotifierProvider<HeavyInventoryController, List<HeavyPart>>
heavyInventoryProvider =
    AsyncNotifierProvider<HeavyInventoryController, List<HeavyPart>>(
      HeavyInventoryController.new,
    );

class HeavyInventoryController extends AsyncNotifier<List<HeavyPart>> {
  @override
  Future<List<HeavyPart>> build() async {
    final dataSource = ref.watch(heavyPartDataSourceProvider);
    return dataSource.loadParts();
  }

  Future<void> addPart(HeavyPart part) async {
    final dataSource = ref.read(heavyPartDataSourceProvider);
    final createdPart = await dataSource.addPart(part);
    final currentParts = state.value ?? [];
    state = AsyncData([...currentParts, createdPart]);
  }

  Future<void> updatePart(HeavyPart updatedPart) async {
    final dataSource = ref.read(heavyPartDataSourceProvider);
    await dataSource.updatePart(updatedPart);
    final currentParts = state.value ?? [];
    state = AsyncData([
      for (final part in currentParts)
        if (part.id == updatedPart.id) updatedPart else part,
    ]);
  }

  Future<void> removePart(String id) async {
    final dataSource = ref.read(heavyPartDataSourceProvider);
    await dataSource.removePart(id);
    final currentParts = state.value ?? [];
    state = AsyncData([
      for (final part in currentParts)
        if (part.id != id) part,
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final dataSource = ref.read(heavyPartDataSourceProvider);
      return dataSource.loadParts();
    });
  }
}
