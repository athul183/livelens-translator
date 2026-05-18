import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

class AppSettingsState {
  final String sourceLanguage;
  final String targetLanguage;
  final bool autoDetect;
  final bool ttsEnabled;

  const AppSettingsState({
    this.sourceLanguage = AppConstants.defaultSourceLanguage,
    this.targetLanguage = AppConstants.defaultTargetLanguage,
    this.autoDetect = AppConstants.defaultAutoDetect,
    this.ttsEnabled = false,
  });

  AppSettingsState copyWith({
    String? sourceLanguage,
    String? targetLanguage,
    bool? autoDetect,
    bool? ttsEnabled,
  }) =>
      AppSettingsState(
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        autoDetect: autoDetect ?? this.autoDetect,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final StorageService _storage;

  AppSettingsNotifier(this._storage) : super(const AppSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final source = _storage.getSetting<String>(AppConstants.sourceLanguageKey) ??
        AppConstants.defaultSourceLanguage;
    final target = _storage.getSetting<String>(AppConstants.targetLanguageKey) ??
        AppConstants.defaultTargetLanguage;
    final autoDetect =
        _storage.getSetting<bool>(AppConstants.autoDetectKey) ??
            AppConstants.defaultAutoDetect;
    final tts = _storage.getSetting<bool>(AppConstants.ttsEnabledKey) ?? false;

    state = AppSettingsState(
      sourceLanguage: source,
      targetLanguage: target,
      autoDetect: autoDetect,
      ttsEnabled: tts,
    );
  }

  Future<void> setSourceLanguage(String code) async {
    state = state.copyWith(sourceLanguage: code);
    await _storage.setSetting(AppConstants.sourceLanguageKey, code);
  }

  Future<void> setTargetLanguage(String code) async {
    state = state.copyWith(targetLanguage: code);
    await _storage.setSetting(AppConstants.targetLanguageKey, code);
  }

  Future<void> toggleAutoDetect() async {
    final newVal = !state.autoDetect;
    state = state.copyWith(autoDetect: newVal);
    await _storage.setSetting(AppConstants.autoDetectKey, newVal);
  }

  Future<void> toggleTts() async {
    final newVal = !state.ttsEnabled;
    state = state.copyWith(ttsEnabled: newVal);
    await _storage.setSetting(AppConstants.ttsEnabledKey, newVal);
  }

  Future<void> swapLanguages() async {
    final temp = state.sourceLanguage;
    await setSourceLanguage(state.targetLanguage);
    await setTargetLanguage(temp);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier(ref.watch(storageServiceProvider));
});
