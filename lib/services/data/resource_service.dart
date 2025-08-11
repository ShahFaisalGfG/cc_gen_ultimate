import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../core/platform_service.dart';
import '../shared/exceptions.dart';

class ResourceService {
  static const String _assetsPath = 'assets/bundled';

  static Future<void> extractBundledResources() async {
    final appDir = await PlatformService.getAppDirectory();
    await _extractPythonEnvironment(appDir);
    await _extractFFmpeg(appDir);
  }

  static Future<void> _extractPythonEnvironment(String appDir) async {
    if (Platform.isAndroid) {
      final pythonZip = await rootBundle.load('$_assetsPath/python_android.zip');
      final archive = ZipDecoder().decodeBytes(pythonZip.buffer.asUint8List());
      
      for (final file in archive) {
        final filePath = path.join(appDir, 'python', file.name);
        if (file.isFile) {
          final fileData = file.content as List<int>;
          await File(filePath).create(recursive: true);
          await File(filePath).writeAsBytes(fileData);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
    }
  }

  static Future<void> _extractFFmpeg(String appDir) async {
    if (Platform.isAndroid) {
      final ffmpegZip = await rootBundle.load('$_assetsPath/ffmpeg_android.zip');
      final archive = ZipDecoder().decodeBytes(ffmpegZip.buffer.asUint8List());
      
      for (final file in archive) {
        final filePath = path.join(appDir, 'ffmpeg', file.name);
        if (file.isFile) {
          final fileData = file.content as List<int>;
          await File(filePath).create(recursive: true);
          await File(filePath).writeAsBytes(fileData);
          
          // Set execute permission for binaries
          if (file.name.contains('ffmpeg') || file.name.contains('ffprobe')) {
            await Process.run('chmod', ['+x', filePath]);
          }
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
    }
  }

  static Future<void> verifyResources() async {
    try {
      await _verifyPython();
      await _verifyFFmpeg();
    } catch (e) {
      throw InstallationException('Resource verification failed: $e');
    }
  }

  static Future<void> _verifyPython() async {
    try {
      final result = await Process.run('python', ['--version']);
      if (result.exitCode != 0) {
        throw InstallationException('Python verification failed');
      }
    } catch (e) {
      throw InstallationException('Python is not properly installed: $e');
    }
  }

  static Future<void> _verifyFFmpeg() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode != 0) {
        throw InstallationException('FFmpeg verification failed');
      }
    } catch (e) {
      throw InstallationException('FFmpeg is not properly installed: $e');
    }
  }
}
