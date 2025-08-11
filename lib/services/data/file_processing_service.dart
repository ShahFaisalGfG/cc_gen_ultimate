import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class FileProcessingService {
  // Supported formats
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];
  static const List<String> supportedVideoFormats = ['mp4', 'mkv', 'avi', 'mov', 'webm'];

  /// Validate file format
  static bool isSupportedFormat(String filePath) {
    final ext = path.extension(filePath).replaceFirst('.', '').toLowerCase();
    return supportedAudioFormats.contains(ext) || supportedVideoFormats.contains(ext);
  }

  /// Generate output file name
  static String generateOutputFileName(String inputPath, String suffix, {String? newExtension}) {
    final dir = path.dirname(inputPath);
    final base = path.basenameWithoutExtension(inputPath);
    final ext = newExtension ?? path.extension(inputPath);
    return path.join(dir, '${base}_$suffix$ext');
  }

  /// Process file with FFmpeg
  static Future<void> processFile({
    required String inputPath,
    required String outputPath,
    required String ffmpegCommand,
  }) async {
    final command = ffmpegCommand
        .replaceAll('{input}', inputPath)
        .replaceAll('{output}', outputPath);
    await FFmpegKit.execute(command);
  }
}
