import '../../domain/repositories/translation_repository.dart';
import '../../services/translation_service.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final TranslationService _translationService;

  TranslationRepositoryImpl({required TranslationService translationService})
      : _translationService = translationService;

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) =>
      _translationService.translate(
        text: text,
        targetCode: targetLanguage,
        sourceCode: sourceLanguage,
      );

  @override
  Future<String?> detectLanguage(String text) async {
    return null;
  }

  @override
  Future<bool> isModelDownloaded(String languageCode) =>
      _translationService.isModelDownloaded(languageCode);

  @override
  Future<void> downloadModel(
    String languageCode, {
    void Function(double progress)? onProgress,
  }) async {
    await _translationService.downloadModel(languageCode,
        onProgress: onProgress);
  }

  @override
  Future<void> deleteModel(String languageCode) async {
    await _translationService.deleteModel(languageCode);
  }

  @override
  Future<List<String>> getDownloadedModels() =>
      _translationService.getDownloadedModels();

  @override
  Future<void> dispose() => _translationService.dispose();
}
