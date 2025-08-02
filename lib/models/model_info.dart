
enum ModelType { whisperAI, libreTranslate }
enum ModelStatus { downloaded, downloading, available, failed }

class ModelInfo {
  final String name;
  final ModelType type;
  final String version;
  final int sizeInMB;
  final int vramRequiredMB;
  final List<String> supportedLanguages;
  final String capabilities;
  final ModelStatus status;
  final double? downloadProgress;
  final double? downloadSpeed;
  final DateTime? lastUsed;
  final bool isVerified;
  final bool updateAvailable;

  const ModelInfo({
    required this.name,
    required this.type,
    required this.version,
    required this.sizeInMB,
    required this.vramRequiredMB,
    required this.supportedLanguages,
    required this.capabilities,
    required this.status,
    this.downloadProgress,
    this.downloadSpeed,
    this.lastUsed,
    this.isVerified = false,
    this.updateAvailable = false,
  });

  String get estimatedDownloadTime {
    if (downloadSpeed == null || downloadSpeed! <= 0) return 'Unknown';
    final minutes = (sizeInMB / (downloadSpeed! * 60)).round();
    return '$minutes min';
  }

  String get formattedSize => '${sizeInMB}MB';
  String get formattedVram => '~${vramRequiredMB / 1024}GB';
}
