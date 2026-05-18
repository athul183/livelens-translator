import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/text_block.dart' as entities;
import '../core/errors/failures.dart';

class OcrService {
  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void initialize() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
  }

  Future<entities.OcrResult> processImage(
    CameraImage cameraImage,
    InputImageRotation rotation,
    Size previewSize,
  ) async {
    if (!_isInitialized || _textRecognizer == null) {
      throw const OcrFailure(message: 'OCR service not initialized');
    }
    if (_isProcessing) {
      return entities.OcrResult(
        blocks: [],
        timestamp: DateTime.now(),
        imageSize: previewSize,
      );
    }

    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(cameraImage, rotation);
      if (inputImage == null) {
        return entities.OcrResult(
          blocks: [],
          timestamp: DateTime.now(),
          imageSize: previewSize,
        );
      }

      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage);

      final blocks = <entities.TextBlock>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final rawRect = line.boundingBox;
          final scaledRect = _scaleRect(
            rawRect,
            Size(
              cameraImage.width.toDouble(),
              cameraImage.height.toDouble(),
            ),
            previewSize,
          );

          if (line.text.trim().isNotEmpty) {
            blocks.add(entities.TextBlock(
              text: line.text.trim(),
              boundingBox: scaledRect,
              confidence: line.confidence ?? 1.0,
            ));
          }
        }
      }

      return entities.OcrResult(
        blocks: blocks,
        timestamp: DateTime.now(),
        imageSize: previewSize,
      );
    } catch (e) {
      debugPrint('[OcrService] Error: $e');
      return entities.OcrResult(
        blocks: [],
        timestamp: DateTime.now(),
        imageSize: previewSize,
      );
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(
      CameraImage image, InputImageRotation rotation) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('[OcrService] buildInputImage error: $e');
      return null;
    }
  }

  Rect _scaleRect(Rect rect, Size imageSize, Size previewSize) {
    if (imageSize.width == 0 || imageSize.height == 0 ||
        previewSize.width == 0 || previewSize.height == 0) {
      return rect;
    }
    final double scaleX = previewSize.width / imageSize.width;
    final double scaleY = previewSize.height / imageSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  Future<void> dispose() async {
    if (_isInitialized && _textRecognizer != null) {
      await _textRecognizer!.close();
      _isInitialized = false;
    }
  }
}
