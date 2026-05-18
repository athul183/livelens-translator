import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/translation_history.dart';

class StorageService {
  Box<TranslationHistory>? _historyBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(TranslationHistoryAdapter());
      _historyBox = await Hive.openBox<TranslationHistory>(
          AppConstants.translationHistoryBox);
      _settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
      _isInitialized = true;
      debugPrint('[StorageService] Initialized');
    } catch (e) {
      debugPrint('[StorageService] Error initializing: $e');
      rethrow;
    }
  }


  Future<void> saveHistory(TranslationHistory record) async {
    _ensureInitialized();
    try {
      await _historyBox!.put(record.id, record);
      final maxHistory = getSetting<int>(AppConstants.maxHistoryKey) ??
          AppConstants.defaultMaxHistory;
      if (_historyBox!.length > maxHistory) {
        final keys = _historyBox!.keys.toList();
        await _historyBox!.delete(keys.first);
      }
    } catch (e) {
      debugPrint('[StorageService] saveHistory error: $e');
    }
  }

  List<TranslationHistory> getAllHistory() {
    _ensureInitialized();
    final list = _historyBox!.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> deleteHistory(String id) async {
    _ensureInitialized();
    await _historyBox!.delete(id);
  }

  Future<void> clearHistory() async {
    _ensureInitialized();
    await _historyBox!.clear();
  }

  Future<TranslationHistory?> toggleFavorite(String id) async {
    _ensureInitialized();
    final record = _historyBox!.get(id);
    if (record == null) return null;
    final updated = record.copyWith(isFavorite: !record.isFavorite);
    await _historyBox!.put(id, updated);
    return updated;
  }

  List<TranslationHistory> getFavorites() {
    _ensureInitialized();
    return _historyBox!.values.where((h) => h.isFavorite).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }


  T? getSetting<T>(String key) {
    if (!_isInitialized || _settingsBox == null) return null;
    return _settingsBox!.get(key) as T?;
  }

  Future<void> setSetting<T>(String key, T value) async {
    _ensureInitialized();
    await _settingsBox!.put(key, value);
  }


  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('[StorageService] Not initialized. Call initialize() first.');
    }
  }

  Future<void> dispose() async {
    await _historyBox?.close();
    await _settingsBox?.close();
    _isInitialized = false;
  }
}
