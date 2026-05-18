class LanguageModel {
  final String languageCode;
  final String displayName;
  final String flagEmoji;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;

  const LanguageModel({
    required this.languageCode,
    required this.displayName,
    required this.flagEmoji,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  LanguageModel copyWith({
    String? languageCode,
    String? displayName,
    String? flagEmoji,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    return LanguageModel(
      languageCode: languageCode ?? this.languageCode,
      displayName: displayName ?? this.displayName,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode;

  @override
  int get hashCode => languageCode.hashCode;

  @override
  String toString() =>
      'LanguageModel($languageCode, downloaded: $isDownloaded)';
}
