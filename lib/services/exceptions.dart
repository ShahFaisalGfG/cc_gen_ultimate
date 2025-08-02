class WhisperException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  WhisperException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'WhisperException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ModelDownloadException extends WhisperException {
  ModelDownloadException(super.message, {super.code, super.originalError});
}

class TranscriptionException extends WhisperException {
  TranscriptionException(super.message, {super.code, super.originalError});
}

class InstallationException extends WhisperException {
  InstallationException(super.message, {super.code, super.originalError});
}

class PlatformException implements Exception {
  final String message;
  PlatformException(this.message);
  
  @override
  String toString() => 'PlatformException: $message';
}

class ServiceException implements Exception {
  final String message;
  final String code;

  ServiceException(this.message, this.code);

  @override
  String toString() => 'ServiceException($code): $message';
}
