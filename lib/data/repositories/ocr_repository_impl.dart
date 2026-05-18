import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/entities/text_block.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../../services/ocr_service.dart';

class OcrRepositoryImpl implements OcrRepository {
  final OcrService _ocrService;

  OcrRepositoryImpl({required OcrService ocrService})
      : _ocrService = ocrService {
    _ocrService.initialize();
  }

  @override
  Future<OcrResult> recognizeText(
    CameraImage image,
    InputImageRotation rotation,
  ) async {
    return _ocrService.processImage(
      image,
      rotation,
      Size.zero,
    );
  }

  @override
  Future<void> dispose() => _ocrService.dispose();
}
