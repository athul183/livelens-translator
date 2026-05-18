abstract class TranslationRepository {
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  });

  Future<String?> detectLanguage(String text);

  Future<bool> isModelDownloaded(String languageCode);

  Future<void> downloadModel(
    String languageCode, {
    void Function(double progress)? onProgress,
  });

  Future<void> deleteModel(String languageCode);

  Future<List<String>> getDownloadedModels();

  Future<void> dispose();
}
