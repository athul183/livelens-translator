import '../entities/translation_history.dart';

abstract class HistoryRepository {
  Future<void> saveHistory(TranslationHistory history);

  Future<List<TranslationHistory>> getAllHistory();

  Future<void> deleteHistory(String id);

  Future<void> clearHistory();

  Future<TranslationHistory> toggleFavorite(String id);

  Future<List<TranslationHistory>> getFavorites();
}
