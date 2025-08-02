class WhisperModel {
  final String name;
  final String size;
  final String status;
  double? progress;

  WhisperModel({
    required this.name,
    required this.size,
    required this.status,
    this.progress,
  });

  factory WhisperModel.fromJson(Map<String, dynamic> json) {
    return WhisperModel(
      name: json['name'] as String,
      size: json['size'] as String,
      status: json['status'] as String,
      progress: json['progress'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'status': status,
      'progress': progress,
    };
  }

  WhisperModel copyWith({
    String? name,
    String? size,
    String? status,
    double? progress,
  }) {
    return WhisperModel(
      name: name ?? this.name,
      size: size ?? this.size,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
