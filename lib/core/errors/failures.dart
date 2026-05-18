abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class CameraFailure extends Failure {
  const CameraFailure({required super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class OcrFailure extends Failure {
  const OcrFailure({required super.message, super.code});
}

class TranslationFailure extends Failure {
  const TranslationFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class ModelNotDownloadedFailure extends Failure {
  const ModelNotDownloadedFailure({required super.message, super.code});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class UnsupportedLanguageFailure extends Failure {
  const UnsupportedLanguageFailure({required super.message, super.code});
}

class LowMemoryFailure extends Failure {
  const LowMemoryFailure({required super.message, super.code});
}
