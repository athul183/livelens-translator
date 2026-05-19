import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/text_block.dart' as entities;
import '../core/errors/failures.dart';

/// A single text line from still-photo OCR, with its bounding rect.
class PhotoTextBlock {
  final String text;
  final Rect boundingBox;
  const PhotoTextBlock({required this.text, required this.boundingBox});
}

/// Result of still-photo OCR: blocks + original image dimensions.
class PhotoOcrResult {
  final List<PhotoTextBlock> blocks;
  final Size imageSize;
  const PhotoOcrResult({required this.blocks, required this.imageSize});
  bool get isEmpty => blocks.isEmpty;
}

/// Service wrapper around ML Kit Text Recognition.
/// Supports both live camera-stream OCR and still-photo file OCR.
class OcrService {
  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void initialize() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
  }

  // ─── Live Camera Frame OCR ─────────────────────────────────────────────────

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

  // ─── Still Photo File OCR ──────────────────────────────────────────────────

  /// Build an [InputImage] directly from a [File] (for still photo OCR).
  InputImage? inputImageFromFile(File file) {
    try {
      return InputImage.fromFile(file);
    } catch (e) {
      debugPrint('[OcrService] inputImageFromFile error: $e');
      return null;
    }
  }

  /// Run OCR on a still-photo [InputImage] and return recognized text blocks
  /// with their bounding boxes and the original image size.
  Future<PhotoOcrResult> recognizeFromFile(InputImage inputImage) async {
    if (!_isInitialized || _textRecognizer == null) {
      initialize();
    }

    try {
      final RecognizedText result =
          await _textRecognizer!.processImage(inputImage);

      // Extract image size from metadata if available
      Size imageSize = Size.zero;
      if (inputImage.metadata != null) {
        imageSize = inputImage.metadata!.size;
      }

      final blocks = <PhotoTextBlock>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) {
            blocks.add(PhotoTextBlock(
              text: text,
              boundingBox: line.boundingBox,
            ));
          }
        }
      }
      return PhotoOcrResult(blocks: blocks, imageSize: imageSize);
    } catch (e) {
      debugPrint('[OcrService] recognizeFromFile error: $e');
      return PhotoOcrResult(blocks: [], imageSize: Size.zero);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
