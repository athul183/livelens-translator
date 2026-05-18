import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../data/repositories/ocr_repository_impl.dart';
import '../data/repositories/translation_repository_impl.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/repositories/ocr_repository.dart';
import '../domain/repositories/translation_repository.dart';
import '../domain/repositories/history_repository.dart';


final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(service.dispose);
  return service;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  ref.onDispose(service.dispose);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});


final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  return OcrRepositoryImpl(ocrService: ref.watch(ocrServiceProvider));
});

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl(
      translationService: ref.watch(translationServiceProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
      storageService: ref.watch(storageServiceProvider));
});
