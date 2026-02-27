import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model_manager.dart';
import '../../domain/sherpa_model.dart';

final modelsViewModelProvider = StateNotifierProvider<ModelsViewModel, List<SherpaModel>>((ref) {
  final manager = ref.watch(modelManagerProvider);
  return ModelsViewModel(manager);
});

final downloadProgressProvider = StateProvider<Map<String, double>>((ref) => {});

class ModelsViewModel extends StateNotifier<List<SherpaModel>> {
  final ModelManager _manager;

  ModelsViewModel(this._manager) : super([]) {
    _init();
  }

  Future<void> _init() async {
    debugPrint('ModelsViewModel: Initializing...');
    await _manager.init();
    state = _manager.getAllModels();
    debugPrint('ModelsViewModel: Loaded ${state.length} models');
  }
  
  Future<void> refresh() async {
    debugPrint('ModelsViewModel: Refreshing list...');
    state = _manager.getAllModels();
  }

  Future<void> downloadModel(String id, WidgetRef ref) async {
    debugPrint('ModelsViewModel: Request download for $id');
    try {
      int lastUpdate = 0;
      await _manager.downloadModel(id, onProgress: (progress) {
        final now = DateTime.now().millisecondsSinceEpoch;
        // Throttle updates to every 100ms
        if (now - lastUpdate > 100) {
          lastUpdate = now;
          ref.read(downloadProgressProvider.notifier).update((state) {
            return {...state, id: progress};
          });
        }
      });
      
      // Ensure 100% is shown briefly or cleared
      ref.read(downloadProgressProvider.notifier).update((state) {
         return {...state, id: 1.0};
      });

      // Refresh list after download
      state = _manager.getAllModels();
      
      // Clear progress after a short delay to let user see 100%
      await Future.delayed(const Duration(milliseconds: 500));
      ref.read(downloadProgressProvider.notifier).update((state) {
        final newState = {...state};
        newState.remove(id);
        return newState;
      });
      debugPrint('ModelsViewModel: Download finished for $id');
    } catch (e) {
      debugPrint("ModelsViewModel: Error downloading model: $e");
      // Clear progress on error
      ref.read(downloadProgressProvider.notifier).update((state) {
        final newState = {...state};
        newState.remove(id);
        return newState;
      });
    }
  }

  Future<void> deleteModel(String id) async {
    debugPrint('ModelsViewModel: Request delete for $id');
    await _manager.deleteModel(id);
    state = _manager.getAllModels();
  }

  Future<void> clearAll() async {
    debugPrint('ModelsViewModel: Request clear all');
    await _manager.clearCache();
    state = _manager.getAllModels();
  }
}
