import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import 'settings_provider.dart';
import 'service_providers.dart';

/// Status of a photo capture + OCR + translation pipeline
enum PhotoCaptureStatus {
  idle,
  capturing,
  processing,
  done,
  error,
}

/// A single extracted + translated text item from a still photo
class PhotoTextItem {
  final String originalText;
  final String translatedText;
  final bool isSelected;
  /// Bounding box in original image pixel coordinates (may be Rect.zero if unknown)
  final Rect boundingBox;

  const PhotoTextItem({
    required this.originalText,
    required this.translatedText,
    this.isSelected = false,
    this.boundingBox = Rect.zero,
  });

  PhotoTextItem copyWith({
    String? originalText,
    String? translatedText,
    bool? isSelected,
    Rect? boundingBox,
  }) {
    return PhotoTextItem(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      isSelected: isSelected ?? this.isSelected,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }
}

/// State for the photo capture feature
class PhotoCaptureState {
  final PhotoCaptureStatus status;
  final File? capturedPhoto;
  final List<PhotoTextItem> textItems;
  final String? errorMessage;
  final double processingProgress; // 0.0 – 1.0
  /// Original image dimensions in pixels (used for overlay scaling)
  final Size imageSize;

  const PhotoCaptureState({
    this.status = PhotoCaptureStatus.idle,
    this.capturedPhoto,
    this.textItems = const [],
    this.errorMessage,
    this.processingProgress = 0.0,
    this.imageSize = Size.zero,
  });

  PhotoCaptureState copyWith({
    PhotoCaptureStatus? status,
    File? capturedPhoto,
    List<PhotoTextItem>? textItems,
    String? errorMessage,
    double? processingProgress,
    Size? imageSize,
  }) {
    return PhotoCaptureState(
      status: status ?? this.status,
      capturedPhoto: capturedPhoto ?? this.capturedPhoto,
      textItems: textItems ?? this.textItems,
      errorMessage: errorMessage ?? this.errorMessage,
      processingProgress: processingProgress ?? this.processingProgress,
      imageSize: imageSize ?? this.imageSize,
    );
  }

  bool get hasText => textItems.isNotEmpty;

  /// Full original text joined
  String get fullOriginalText =>
      textItems.map((t) => t.originalText).join('\n');

  /// Full translated text joined
  String get fullTranslatedText =>
      textItems.map((t) => t.translatedText).join('\n');

  /// Only selected items' translated text
  String get selectedTranslatedText => textItems
      .where((t) => t.isSelected)
      .map((t) => t.translatedText)
      .join('\n');
}

/// Notifier that manages photo capture → OCR → translation
class PhotoCaptureNotifier extends StateNotifier<PhotoCaptureState> {
  final OcrService _ocrService;
  final TranslationService _translationService;
  final Ref _ref;

  PhotoCaptureNotifier(this._ocrService, this._translationService, this._ref)
      : super(const PhotoCaptureState());

  /// Process a file photo (already captured by camera)
  Future<void> processPhoto(File photo) async {
    state = PhotoCaptureState(
      status: PhotoCaptureStatus.processing,
      capturedPhoto: photo,
      processingProgress: 0.1,
    );

    try {
      // Run ML Kit OCR on the file
      state = state.copyWith(processingProgress: 0.3);
      final inputImage = _buildInputImageFromFile(photo);
      if (inputImage == null) {
        state = state.copyWith(
          status: PhotoCaptureStatus.error,
          errorMessage: 'Failed to read image',
        );
        return;
      }

      final ocrResult = await _ocrService.recognizeFromFile(inputImage);
      state = state.copyWith(processingProgress: 0.6);

      if (ocrResult.isEmpty) {
        state = state.copyWith(
          status: PhotoCaptureStatus.done,
          textItems: [],
          processingProgress: 1.0,
        );
        return;
      }

      // Translate each block
      final settings = _ref.read(appSettingsProvider);
      final items = <PhotoTextItem>[];
      int i = 0;
      for (final block in ocrResult.blocks) {
        i++;
        state = state.copyWith(
          processingProgress: 0.6 + (i / ocrResult.blocks.length) * 0.4,
        );
        if (block.text.trim().isEmpty) continue;

        final translated = await _translationService.translate(
          text: block.text,
          targetCode: settings.targetLanguage,
          sourceCode: settings.autoDetect ? null : settings.sourceLanguage,
        );

        items.add(PhotoTextItem(
          originalText: block.text,
          translatedText: translated,
          boundingBox: block.boundingBox,
          isSelected: true, // default all selected
        ));
      }

      state = state.copyWith(
        status: PhotoCaptureStatus.done,
        textItems: items,
        imageSize: ocrResult.imageSize,
        processingProgress: 1.0,
      );
    } catch (e) {
      debugPrint('[PhotoCapture] Error: $e');
      state = state.copyWith(
        status: PhotoCaptureStatus.error,
        errorMessage: 'Processing failed: $e',
      );
    }
  }

  /// Toggle selection of a specific text item
  void toggleSelection(int index) {
    if (index < 0 || index >= state.textItems.length) return;
    final updated = List<PhotoTextItem>.from(state.textItems);
    updated[index] = updated[index].copyWith(
      isSelected: !updated[index].isSelected,
    );
    state = state.copyWith(textItems: updated);
  }

  /// Select / deselect all
  void toggleSelectAll(bool selectAll) {
    final updated = state.textItems
        .map((t) => t.copyWith(isSelected: selectAll))
        .toList();
    state = state.copyWith(textItems: updated);
  }

  /// Reset to idle (go back to camera)
  void reset() {
    state = const PhotoCaptureState();
  }

  /// Build InputImage from a file (ML Kit)
  dynamic _buildInputImageFromFile(File file) {
    try {
      return _ocrService.inputImageFromFile(file);
    } catch (e) {
      debugPrint('[PhotoCapture] buildInputImage error: $e');
      return null;
    }
  }
}

final photoCaptureProvider =
    StateNotifierProvider<PhotoCaptureNotifier, PhotoCaptureState>((ref) {
  return PhotoCaptureNotifier(
    ref.watch(ocrServiceProvider),
    ref.watch(translationServiceProvider),
    ref,
  );
});
