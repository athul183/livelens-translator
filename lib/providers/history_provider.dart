import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/translation_history.dart';
import '../domain/repositories/history_repository.dart';
import 'service_providers.dart';

class HistoryNotifier extends StateNotifier<List<TranslationHistory>> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final list = await _repository.getAllHistory();
    state = list;
  }

  Future<void> addHistory(TranslationHistory history) async {
    await _repository.saveHistory(history);
    await loadHistory();
  }

  Future<void> deleteHistory(String id) async {
    await _repository.deleteHistory(id);
    state = state.where((h) => h.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repository.clearHistory();
    state = [];
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadHistory();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<TranslationHistory>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

final favoritesProvider = Provider<List<TranslationHistory>>((ref) {
  return ref.watch(historyProvider).where((h) => h.isFavorite).toList();
});
