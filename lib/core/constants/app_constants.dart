class AppConstants {
  AppConstants._();

  static const String appName = 'LiveLens Translator';
  static const String appVersion = '1.0.0';

  static const String translationHistoryBox = 'translation_history';
  static const String settingsBox = 'settings';
  static const String downloadedModelsBox = 'downloaded_models';

  static const String sourceLanguageKey = 'source_language';
  static const String targetLanguageKey = 'target_language';
  static const String autoDetectKey = 'auto_detect_language';
  static const String darkModeKey = 'dark_mode';
  static const String ttsEnabledKey = 'tts_enabled';
  static const String maxHistoryKey = 'max_history';

  static const String defaultSourceLanguage = 'en';
  static const String defaultTargetLanguage = 'hi';
  static const bool defaultAutoDetect = true;
  static const int defaultMaxHistory = 500;

  static const int maxFps = 2;
  static const int frameIntervalMs = 500;
  static const double minTextConfidence = 0.7;
  static const int translationCacheSize = 100;

  static const double borderRadius = 16.0;
  static const double overlayOpacity = 0.8;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'ml': 'Malayalam',
    'ta': 'Tamil',
    'ar': 'Arabic',
    'ja': 'Japanese',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ko': 'Korean',
    'it': 'Italian',
    'tr': 'Turkish',
  };

  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'hi': '🇮🇳',
    'ml': '🇮🇳',
    'ta': '🇮🇳',
    'ar': '🇸🇦',
    'ja': '🇯🇵',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'es': '🇪🇸',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'zh': '🇨🇳',
    'ko': '🇰🇷',
    'it': '🇮🇹',
    'tr': '🇹🇷',
  };
}
