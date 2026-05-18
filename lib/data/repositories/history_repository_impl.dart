import '../../domain/entities/translation_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../../services/storage_service.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final StorageService _storageService;

  HistoryRepositoryImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<void> saveHistory(TranslationHistory history) =>
      _storageService.saveHistory(history);

  @override
  Future<List<TranslationHistory>> getAllHistory() async =>
      _storageService.getAllHistory();

  @override
  Future<void> deleteHistory(String id) => _storageService.deleteHistory(id);

  @override
  Future<void> clearHistory() => _storageService.clearHistory();

  @override
  Future<TranslationHistory> toggleFavorite(String id) async {
    final updated = await _storageService.toggleFavorite(id);
    if (updated == null) throw StateError('Record $id not found');
    return updated;
  }

  @override
  Future<List<TranslationHistory>> getFavorites() async =>
      _storageService.getFavorites();
}
