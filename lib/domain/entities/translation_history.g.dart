// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranslationHistoryAdapter extends TypeAdapter<TranslationHistory> {
  @override
  final int typeId = 0;

  @override
  TranslationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationHistory(
      id: fields[0] as String?,
      originalText: fields[1] as String,
      translatedText: fields[2] as String,
      sourceLanguage: fields[3] as String,
      targetLanguage: fields[4] as String,
      timestamp: fields[5] as DateTime?,
      isFavorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalText)
      ..writeByte(2)
      ..write(obj.translatedText)
      ..writeByte(3)
      ..write(obj.sourceLanguage)
      ..writeByte(4)
      ..write(obj.targetLanguage)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
