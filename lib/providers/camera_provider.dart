import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/text_block.dart' as domain;
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import 'settings_provider.dart';
import 'service_providers.dart';

enum CameraStatus { uninitialized, initializing, ready, error, permissionDenied }

class CameraState {
  final CameraStatus status;
  final CameraController? controller;
  final List<CameraDescription> cameras;
  final domain.OcrResult? lastOcrResult;
  final bool isProcessing;
  final bool isFrozen;
  final bool flashOn;
  final bool isCapturing; // true while takePicture() is in progress
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final String? errorMessage;
  final Size previewSize;

  const CameraState({
    this.status = CameraStatus.uninitialized,
    this.controller,
    this.cameras = const [],
    this.lastOcrResult,
    this.isProcessing = false,
    this.isFrozen = false,
    this.flashOn = false,
    this.isCapturing = false,
    this.zoomLevel = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 4.0,
    this.errorMessage,
    this.previewSize = Size.zero,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    List<CameraDescription>? cameras,
    domain.OcrResult? lastOcrResult,
    bool? isProcessing,
    bool? isFrozen,
    bool? flashOn,
    bool? isCapturing,
    double? zoomLevel,
    double? minZoom,
    double? maxZoom,
    String? errorMessage,
    Size? previewSize,
  }) =>
      CameraState(
        status: status ?? this.status,
        controller: controller ?? this.controller,
        cameras: cameras ?? this.cameras,
        lastOcrResult: lastOcrResult ?? this.lastOcrResult,
        isProcessing: isProcessing ?? this.isProcessing,
        isFrozen: isFrozen ?? this.isFrozen,
        flashOn: flashOn ?? this.flashOn,
        isCapturing: isCapturing ?? this.isCapturing,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        errorMessage: errorMessage ?? this.errorMessage,
        previewSize: previewSize ?? this.previewSize,
      );
}

class CameraNotifier extends StateNotifier<CameraState> {
  final OcrService _ocrService;
  final TranslationService _translationService;
  final Ref _ref;

  Timer? _frameTimer;
  DateTime _lastFrameTime = DateTime.now();

  CameraNotifier(this._ocrService, this._translationService, this._ref)
      : super(const CameraState()) {
    _ocrService.initialize();
  }

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'No cameras found on this device',
      );
      return;
    }

    state = state.copyWith(
      status: CameraStatus.initializing,
      cameras: cameras,
    );

    try {
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller.initialize();
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      state = state.copyWith(
        status: CameraStatus.ready,
        controller: controller,
        minZoom: minZoom,
        maxZoom: maxZoom,
        previewSize: controller.value.previewSize != null
            ? Size(
                controller.value.previewSize!.width,
                controller.value.previewSize!.height,
              )
            : Size.zero,
      );

      _startFrameProcessing(controller);
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Camera initialization failed: $e',
      );
    }
  }

  void _startFrameProcessing(CameraController controller) {
    controller.startImageStream((CameraImage image) {
      if (state.isFrozen) return;

      final now = DateTime.now();
      if (now.difference(_lastFrameTime).inMilliseconds <
          AppConstants.frameIntervalMs) return;

      _lastFrameTime = now;
      _processFrame(image, controller);
    });
  }

  Future<void> _processFrame(
      CameraImage image, CameraController controller) async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true);

    try {
      final settings = _ref.read(appSettingsProvider);
      final previewSize = state.previewSize;

      final ocrResult = await _ocrService.processImage(
        image,
        _getRotation(controller.description.sensorOrientation),
        previewSize,
      );

      if (ocrResult.blocks.isEmpty) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final translatedBlocks = <domain.TextBlock>[];
      for (final block in ocrResult.blocks) {
        final translated = await _translationService.translate(
          text: block.text,
          targetCode: settings.targetLanguage,
          sourceCode: settings.autoDetect ? null : settings.sourceLanguage,
        );
        translatedBlocks.add(block.copyWith(translatedText: translated));
      }

      state = state.copyWith(
        lastOcrResult: domain.OcrResult(
          blocks: translatedBlocks,
          timestamp: ocrResult.timestamp,
          imageSize: ocrResult.imageSize,
        ),
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false);
    }
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void toggleFreeze() {
    state = state.copyWith(isFrozen: !state.isFrozen);
  }

  Future<void> toggleFlash() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;
    final newFlash = !state.flashOn;
    await controller.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off);
    state = state.copyWith(flashOn: newFlash);
  }

  Future<void> setZoom(double zoom) async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;
    final clamped = zoom.clamp(state.minZoom, state.maxZoom);
    await controller.setZoomLevel(clamped);
    state = state.copyWith(zoomLevel: clamped);
  }

  void clearOcrResult() {
    state = state.copyWith(lastOcrResult: null);
  }

  /// Capture a still photo and return the saved [File].
  /// Pauses the image stream briefly during capture to avoid conflicts.
  Future<String?> capturePhoto() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (state.isCapturing) return null;

    state = state.copyWith(isCapturing: true);
    try {
      // Stop live OCR stream momentarily
      await controller.stopImageStream();
      // Snap photo
      final xFile = await controller.takePicture();
      // Resume stream
      _startFrameProcessing(controller);
      state = state.copyWith(isCapturing: false);
      return xFile.path;
    } catch (e) {
      debugPrint('[Camera] capturePhoto error: $e');
      // Try to resume stream even on error
      try { _startFrameProcessing(controller); } catch (_) {}
      state = state.copyWith(isCapturing: false);
      return null;
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    state.controller?.stopImageStream();
    state.controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}

final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(
    ref.watch(ocrServiceProvider),
    ref.watch(translationServiceProvider),
    ref,
  );
});
