import 'package:flutter/material.dart';

class TextBlock {
  final String text;

  final String? translatedText;

  final Rect boundingBox;

  final double confidence;

  final String? detectedLanguage;

  const TextBlock({
    required this.text,
    this.translatedText,
    required this.boundingBox,
    this.confidence = 1.0,
    this.detectedLanguage,
  });

  TextBlock copyWith({
    String? text,
    String? translatedText,
    Rect? boundingBox,
    double? confidence,
    String? detectedLanguage,
  }) {
    return TextBlock(
      text: text ?? this.text,
      translatedText: translatedText ?? this.translatedText,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox;

  @override
  int get hashCode => Object.hash(text, boundingBox);

  @override
  String toString() => 'TextBlock(text: $text, box: $boundingBox)';
}

class OcrResult {
  final List<TextBlock> blocks;
  final DateTime timestamp;
  final Size imageSize;

  const OcrResult({
    required this.blocks,
    required this.timestamp,
    required this.imageSize,
  });

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;

  String get fullText => blocks.map((b) => b.text).join(' ');

  @override
  String toString() =>
      'OcrResult(blocks: ${blocks.length}, timestamp: $timestamp)';
}
