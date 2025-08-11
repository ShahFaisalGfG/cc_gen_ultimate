import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../shared/exceptions.dart';

class PlatformService {
  static Future<String> getAppDirectory() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'cc_gen_ultimate');
    } else if (Platform.isWindows) {
      return path.join(
        Platform.environment['APPDATA'] ?? '',
        'cc_gen_ultimate'
      );
    }
    throw PlatformException('Unsupported platform');
  }

  static Future<void> setupPythonEnvironment() async {
    if (Platform.isAndroid) {
      await _setupAndroidPython();
    }
  }

  static Future<void> _setupAndroidPython() async {
    final appDir = await getAppDirectory();
    final pythonDir = path.join(appDir, 'python');
    
    if (!await Directory(pythonDir).exists()) {
      // Extract bundled Python environment
      // TODO: Implement Python environment extraction for Android
    }

    // Set environment variables
    Platform.environment['PYTHONHOME'] = pythonDir;
    Platform.environment['PYTHONPATH'] = path.join(pythonDir, 'lib');
  }


  static Future<void> setupFFmpeg() async {
    if (Platform.isAndroid) {
      await _setupAndroidFFmpeg();
    } else if (Platform.isWindows) {
      await _setupWindowsFFmpeg();
    }
  }

  static Future<void> _setupAndroidFFmpeg() async {
    // FFmpeg is bundled with the app on Android
    // Just verify it's accessible
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode != 0) {
        throw InstallationException('FFmpeg is not properly installed on Android');
      }
    } catch (e) {
      throw InstallationException('Failed to access FFmpeg on Android: $e');
    }
  }

  static Future<void> _setupWindowsFFmpeg() async {
    final appDir = await getAppDirectory();
    final ffmpegDir = path.join(appDir, 'ffmpeg');

    if (!await Directory(ffmpegDir).exists()) {
      // TODO: Download and extract FFmpeg for Windows
      // This should be implemented with proper download and verification
    }

    // Add FFmpeg to PATH
    final pathEnv = Platform.environment['PATH'] ?? '';
    Platform.environment['PATH'] = '${path.join(ffmpegDir, "bin")}${Platform.pathSeparator}$pathEnv';
  }
}
