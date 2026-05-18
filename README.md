# LiveLens Translator

> Real-time camera OCR + on-device translation app built with Flutter & Google ML Kit.

---

## Features

| Feature | Details |
|---|---|
| Live Camera OCR | Detects text in real time at ≤ 2 fps |
| On-Device Translation | ML Kit Translation (no internet needed after model download) |
| Text Overlays | Bounding boxes + translated text drawn on camera preview |
| Offline Language Packs | Download / delete 15 language models |
| History | All translations saved to Hive local DB |
| Favorites | Star history items for quick access |
| Text-to-Speech | Reads translated text aloud |
| Copy / Share | Tap any detected block to copy or share |
| Freeze Frame | Pause camera to analyze a still frame |
| Flash Toggle | Torch mode for low-light scanning |
| Zoom | Tap to cycle zoom levels |
| 15 Languages | EN, HI, ML, TA, AR, JA, FR, DE, ES, PT, RU, ZH, KO, IT, TR |

---

## Architecture

```
lib/
├── core/
│   ├── constants/         # AppConstants (language map, keys, fps)
│   ├── errors/            # Failure hierarchy
│   ├── theme/             # AppTheme (dark, glassmorphism)
│   └── utils/             # Language utils, Debouncer
├── data/
│   ├── models/            # (reserved for DTO extensions)
│   └── repositories/      # OcrRepositoryImpl, TranslationRepositoryImpl, HistoryRepositoryImpl
├── domain/
│   ├── entities/          # TextBlock, OcrResult, TranslationHistory, LanguageModel
│   ├── repositories/      # Abstract contracts
│   └── usecases/          # (extensible use-case layer)
├── presentation/
│   ├── overlays/          # TextOverlayPainter (CustomPainter)
│   ├── screens/           # CameraScreen, HistoryScreen, DownloadManagerScreen, SettingsScreen
│   └── widgets/           # GlassCard, GradientButton, GlowIconButton, TranslatePanel, LanguageSelectorSheet
├── providers/             # Riverpod providers (camera, settings, history, download manager, services)
├── services/              # OcrService, TranslationService, StorageService, TtsService
└── main.dart              # App entry + bottom navigation shell
```

---

## Getting Started

### Prerequisites

- Flutter 3.x (`flutter --version`)
- Android SDK ≥ 21 / iOS 14+
- **Windows**: Enable Developer Mode (`start ms-settings:developers`) for symlink support

### 1. Install dependencies

```bash
cd livelens_translator
flutter pub get
```

### 2. Run on device / emulator

```bash
# Android
flutter run

# iOS (requires Mac + Xcode)
flutter run -d ios

# Check connected devices
flutter devices
```

### 3. Build release APK

```bash
flutter build apk --release
```

---

## Platform Setup

### Android

Permissions already configured in `AndroidManifest.xml`:
- `CAMERA`
- `INTERNET`
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`
- `FLASHLIGHT`

ML Kit bundled model meta-data:
```xml
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="ocr" />
```

**minSdk** set to `21` in `android/app/build.gradle.kts`.

### iOS

Usage descriptions in `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

---

## Key Packages

| Package | Version | Purpose |
|---|---|---|
| `camera` | 0.11.x | Live camera preview + image stream |
| `google_mlkit_text_recognition` | 0.13.x | OCR |
| `google_mlkit_translation` | 0.11.x | On-device translation |
| `flutter_riverpod` | 2.5.x | State management |
| `hive` + `hive_flutter` | 2.2.x | Local storage |
| `permission_handler` | 11.x | Runtime permissions |
| `flutter_tts` | 4.x | Text-to-speech |
| `share_plus` | 10.x | Share translated text |
| `google_fonts` | 6.x | Inter typeface |

---

## Supported Languages

| Code | Language | Flag |
|---|---|---|
| `en` | English | 🇺🇸 |
| `hi` | Hindi | 🇮🇳 |
| `ml` | Malayalam | 🇮🇳 |
| `ta` | Tamil | 🇮🇳 |
| `ar` | Arabic | 🇸🇦 |
| `ja` | Japanese | 🇯🇵 |
| `fr` | French | 🇫🇷 |
| `de` | German | 🇩🇪 |
| `es` | Spanish | 🇪🇸 |
| `pt` | Portuguese | 🇵🇹 |
| `ru` | Russian | 🇷🇺 |
| `zh` | Chinese | 🇨🇳 |
| `ko` | Korean | 🇰🇷 |
| `it` | Italian | 🇮🇹 |
| `tr` | Turkish | 🇹🇷 |

---

## Performance

- **Frame rate cap**: 2 fps for OCR to avoid CPU overload
- **Translation cache**: LRU-style in-memory cache (max 150 entries)
- **Duplicate prevention**: `_isProcessing` flag prevents queued frames
- **Lazy model init**: Translators created on-demand and cached
- **Proper dispose**: All camera streams, ML Kit instances, and Hive boxes disposed on screen exit
