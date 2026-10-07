import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/heavy_part_local_data_source.dart';
import '../../domain/entities/heavy_part.dart';

final FutureProvider<HeavyPartLocalDataSource>
heavyPartLocalDataSourceProvider = FutureProvider<HeavyPartLocalDataSource>((
  ref,
) async {
  final preferences = await SharedPreferences.getInstance();
  return HeavyPartLocalDataSource(preferences);
});

final AsyncNotifierProvider<HeavyInventoryController, List<HeavyPart>>
heavyInventoryProvider =
    AsyncNotifierProvider<HeavyInventoryController, List<HeavyPart>>(
      HeavyInventoryController.new,
    );

class HeavyInventoryController extends AsyncNotifier<List<HeavyPart>> {
  @override
  Future<List<HeavyPart>> build() async {
    final dataSource = await ref.watch(heavyPartLocalDataSourceProvider.future);
    return dataSource.loadParts();
  }

  Future<void> addPart(HeavyPart part) async {
    final currentParts = state.requireValue;
    final updatedParts = [...currentParts, part];
    final dataSource = await ref.read(heavyPartLocalDataSourceProvider.future);
    await dataSource.saveParts(updatedParts);
    state = AsyncData(updatedParts);
  }

  Future<void> updatePart(HeavyPart updatedPart) async {
    final updatedParts = [
      for (final part in state.requireValue)
        if (part.id == updatedPart.id) updatedPart else part,
    ];
    final dataSource = await ref.read(heavyPartLocalDataSourceProvider.future);
    await dataSource.saveParts(updatedParts);
    state = AsyncData(updatedParts);
  }

  Future<void> removePart(String id) async {
    final updatedParts = [
      for (final part in state.requireValue)
        if (part.id != id) part,
    ];
    final dataSource = await ref.read(heavyPartLocalDataSourceProvider.future);
    await dataSource.saveParts(updatedParts);
    state = AsyncData(updatedParts);
  }
}
