import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../core/utils/language_utils.dart';

class TranslationService {
  final Map<String, String> _cache = {};

  final Map<String, OnDeviceTranslator> _translators = {};

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  int get cacheSize => _cache.length;

  Future<String> translate({
    required String text,
    required String targetCode,
    String? sourceCode,
  }) async {
    if (text.trim().isEmpty) return text;

    final effectiveSource = (sourceCode == null || sourceCode.isEmpty)
        ? 'en'
        : sourceCode;

    if (effectiveSource == targetCode) return text;

    final cacheKey = '$effectiveSource|$targetCode|$text';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final translator = _getOrCreateTranslator(effectiveSource, targetCode);
      final result = await translator.translateText(text);
      _cache[cacheKey] = result;

      if (_cache.length > 150) {
        final firstKey = _cache.keys.first;
        _cache.remove(firstKey);
      }

      return result;
    } catch (e) {
      debugPrint('[TranslationService] translate error: $e');
      return text;
    }
  }

  OnDeviceTranslator _getOrCreateTranslator(
      String sourceCode, String targetCode) {
    final key = '$sourceCode→$targetCode';
    if (!_translators.containsKey(key)) {
      final source = codeToTranslateLanguage(sourceCode) ??
          TranslateLanguage.english;
      final target = codeToTranslateLanguage(targetCode) ??
          TranslateLanguage.hindi;
      _translators[key] = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
    }
    return _translators[key]!;
  }
  
  Future<bool> isModelDownloaded(String languageCode) async {
    try {
      final lang = codeToTranslateLanguage(languageCode);
      if (lang == null) return false;
      return await _modelManager.isModelDownloaded(lang.bcpCode);
    } catch (e) {
      debugPrint('[TranslationService] isModelDownloaded error: $e');
      return false;
    }
  }

  Future<bool> downloadModel(
    String languageCode, {
    void Function(double)? onProgress,
  }) async {
    try {
      final lang = codeToTranslateLanguage(languageCode);
      if (lang == null) return false;

      onProgress?.call(0.1);
      await Future.delayed(const Duration(milliseconds: 500));
      onProgress?.call(0.3);

      final success =
          await _modelManager.downloadModel(lang.bcpCode, isWifiRequired: false);

      onProgress?.call(success ? 1.0 : 0.0);
      return success;
    } catch (e) {
      debugPrint('[TranslationService] downloadModel error: $e');
      onProgress?.call(0.0);
      return false;
    }
  }

  Future<bool> deleteModel(String languageCode) async {
    try {
      final lang = codeToTranslateLanguage(languageCode);
      if (lang == null) return false;

      final keysToRemove = _translators.keys
          .where((k) => k.startsWith(languageCode) || k.endsWith(languageCode))
          .toList();
      for (final key in keysToRemove) {
        await _translators[key]?.close();
        _translators.remove(key);
      }

      return await _modelManager.deleteModel(lang.bcpCode);
    } catch (e) {
      debugPrint('[TranslationService] deleteModel error: $e');
      return false;
    }
  }

  Future<List<String>> getDownloadedModels() async {
    const codes = [
      'en', 'hi', 'ml', 'ta', 'ar', 'ja',
      'fr', 'de', 'es', 'pt', 'ru', 'zh', 'ko', 'it', 'tr',
    ];
    final downloaded = <String>[];
    for (final code in codes) {
      if (await isModelDownloaded(code)) {
        downloaded.add(code);
      }
    }
    return downloaded;
  }

  Future<void> dispose() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
    _cache.clear();
  }
}
