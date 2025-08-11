class PythonEnvironmentException implements Exception {
  final String message;
  final dynamic originalError;
  final String? code;

  PythonEnvironmentException(
    this.message, {
    this.originalError,
    this.code,
  });

  @override
  String toString() => 'PythonEnvironmentException: $message${code != null ? ' (Code: $code)' : ''}';
}

class FFmpegException implements Exception {
  final String message;
  final dynamic originalError;
  final String? code;

  FFmpegException(
    this.message, {
    this.originalError,
    this.code,
  });

  @override
  String toString() => 'FFmpegException: $message${code != null ? ' (Code: $code)' : ''}';
}

class PlatformNotSupportedException implements Exception {
  final String message;
  final String platform;

  PlatformNotSupportedException(this.platform, [this.message = '']);

  @override
  String toString() => 'PlatformNotSupportedException: ${message.isNotEmpty ? message : 'Platform $platform is not supported'}';
}
