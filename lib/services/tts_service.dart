import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] init error: $e');
    }
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (!_isInitialized) await initialize();
    try {
      await _tts.setLanguage(language);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speak error: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await stop();
  }
}
