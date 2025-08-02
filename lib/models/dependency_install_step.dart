class DependencyInstallStep {
  final String name;
  final String details;
  final double? progress;
  final bool success;
  final String? error;
  final String? logs;

  DependencyInstallStep({
    required this.name,
    required this.details,
    this.progress,
    this.success = false,
    this.error,
    this.logs,
  });

  DependencyInstallStep copyWith({
    String? name,
    String? details,
    double? progress,
    bool? success,
    String? error,
    String? logs,
  }) {
    return DependencyInstallStep(
      name: name ?? this.name,
      details: details ?? this.details,
      progress: progress ?? this.progress,
      success: success ?? this.success,
      error: error ?? this.error,
      logs: logs ?? this.logs,
    );
  }
}
