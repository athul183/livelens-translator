import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/language_utils.dart';
import '../domain/entities/language_model.dart';
import '../services/translation_service.dart';
import 'service_providers.dart';

class DownloadManagerNotifier extends StateNotifier<List<LanguageModel>> {
  final TranslationService _translationService;

  DownloadManagerNotifier(this._translationService) : super([]) {
    _buildInitialState();
  }

  Future<void> _buildInitialState() async {
    final models = AppConstants.supportedLanguages.entries.map((entry) {
      return LanguageModel(
        languageCode: entry.key,
        displayName: entry.value,
        flagEmoji: languageFlag(entry.key),
      );
    }).toList();
    state = models;
    await refreshDownloadStatus();
  }

  Future<void> refreshDownloadStatus() async {
    final updated = <LanguageModel>[];
    for (final model in state) {
      final isDownloaded =
          await _translationService.isModelDownloaded(model.languageCode);
      updated.add(model.copyWith(isDownloaded: isDownloaded));
    }
    state = updated;
  }

  Future<void> downloadModel(String languageCode) async {
    _setDownloading(languageCode, true);

    final success = await _translationService.downloadModel(
      languageCode,
      onProgress: (progress) => _setProgress(languageCode, progress),
    );

    _updateModelStatus(languageCode, isDownloaded: success, isDownloading: false);
  }

  Future<void> deleteModel(String languageCode) async {
    final success = await _translationService.deleteModel(languageCode);
    if (success) {
      _updateModelStatus(languageCode, isDownloaded: false);
    }
  }

  void _setDownloading(String code, bool downloading) {
    state = state.map((m) {
      if (m.languageCode == code) {
        return m.copyWith(isDownloading: downloading, downloadProgress: 0.0);
      }
      return m;
    }).toList();
  }

  void _setProgress(String code, double progress) {
    state = state.map((m) {
      if (m.languageCode == code) {
        return m.copyWith(downloadProgress: progress);
      }
      return m;
    }).toList();
  }

  void _updateModelStatus(
    String code, {
    bool? isDownloaded,
    bool? isDownloading,
  }) {
    state = state.map((m) {
      if (m.languageCode == code) {
        return m.copyWith(
          isDownloaded: isDownloaded,
          isDownloading: isDownloading ?? false,
          downloadProgress: 0.0,
        );
      }
      return m;
    }).toList();
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManagerNotifier, List<LanguageModel>>((ref) {
  return DownloadManagerNotifier(ref.watch(translationServiceProvider));
});

final downloadedModelsProvider = Provider<List<LanguageModel>>((ref) {
  return ref.watch(downloadManagerProvider).where((m) => m.isDownloaded).toList();
});
