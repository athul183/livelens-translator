import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../constants/app_constants.dart';

TranslateLanguage? codeToTranslateLanguage(String code) {
  try {
    return TranslateLanguage.values.firstWhere(
      (lang) => lang.bcpCode == code,
    );
  } catch (_) {
    return null;
  }
}

String translateLanguageToCode(TranslateLanguage lang) {
  return lang.bcpCode;
}

String languageDisplayName(String code) {
  return AppConstants.supportedLanguages[code] ?? code.toUpperCase();
}

String languageFlag(String code) {
  return AppConstants.languageFlags[code] ?? '🌐';
}

String formatDateTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${dt.day}/${dt.month}/${dt.year}';
}

Rect clampRect(Rect rect, Size screenSize) {
  return Rect.fromLTRB(
    rect.left.clamp(0, screenSize.width),
    rect.top.clamp(0, screenSize.height),
    rect.right.clamp(0, screenSize.width),
    rect.bottom.clamp(0, screenSize.height),
  );
}

class Debouncer {
  final Duration delay;
  VoidCallback? _action;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _action = action;
    Future.delayed(delay, () {
      if (_action == action) {
        _action!();
      }
    });
  }

  void cancel() => _action = null;
}
