import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'translation_history.g.dart';

@HiveType(typeId: 0)
class TranslationHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalText;

  @HiveField(2)
  final String translatedText;

  @HiveField(3)
  final String sourceLanguage;

  @HiveField(4)
  final String targetLanguage;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final bool isFavorite;

  TranslationHistory({
    String? id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    DateTime? timestamp,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  TranslationHistory copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return TranslationHistory(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() =>
      'TranslationHistory(id: $id, source: $sourceLanguage → $targetLanguage)';
}
