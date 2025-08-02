import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'python_environment_service.dart';
import '../models/dependency_install_step.dart';

class DependencyManager {
  final PythonEnvironmentService _pythonEnv = PythonEnvironmentService();
  
  // ignore: unused_field
  static const Map<String, String> _requiredPackages = {
    'faster-whisper': '1.1.1',
    'libretranslate': '1.7.2',
  };

  Future<Map<String, bool>> getDependencyStatus() async {
    final status = <String, bool>{
      'python': false,
      'pip': false,
      'ffmpeg': false,
      'faster-whisper': false,
      'libretranslate': false,
    };

    // Check dependencies in order
    status['python'] = await _pythonEnv.isPythonInstalled();
    if (!status['python']!) return status;  // Stop if Python is not installed

    status['pip'] = await _pythonEnv.verifyPip();
    if (!status['pip']!) return status;  // Stop if pip is not installed

    status['ffmpeg'] = await isFFmpegInstalled();
    if (!status['ffmpeg']!) return status;  // Stop if ffmpeg is not installed

    status['faster-whisper'] = await _pythonEnv.verifyPackage('faster-whisper');
    if (!status['faster-whisper']!) return status;  // Stop if faster-whisper is not installed

    // alternative check for faster-whisper
    //status['faster-whisper'] = await isOpenAIWhisperInstalled();
    //if (!status['faster-whisper']!) return status;  // Stop if faster-whisper is not installed

    status['libretranslate'] = await _pythonEnv.verifyPackage('libretranslate');
    if (!status['libretranslate']!) return status;  // Stop if libretranslate is not installed

    // alternative check for libretranslate
    // status['libretranslate'] = await _pythonEnv.verifyPackage('libretranslate');
    // if (!status['libretranslate']!) return status;  // Stop if libretranslate is not installed

    return status;
  }

  Future<bool> isFFmpegInstalled() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLibreTranslateInstalled() async {
    try {
      final result = await Process.run('libretranslate', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isArgosTranslateInstalled() async {
    try {
      final result = await Process.run('argostranslate', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isEsTranslatorInstalled() async {
    try {
      final result = await Process.run('pip', ['show', 'libretranslate']);
      return result.exitCode == 0 && result.stdout.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isFasterWhisperInstalled() async {
    try {
      final result = await Process.run('faster-whisper', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  Future<File> _copyBatchFile(String dependency) async {
    // Use Flutter's asset bundle to load the batch file from assets
    final assetPath = 'assets/installation_scripts/${dependency}_install.bat';
    final tempDir = Directory.systemTemp;
    final tempBatFile = File('${tempDir.path}/${dependency}_install.bat');

    // Load the asset as bytes
    final byteData = await File(assetPath).readAsBytes();
    await tempBatFile.writeAsBytes(byteData);
    // Return the path to the temporary batch file
    return tempBatFile;
  }

  Stream<String> _runBatchFile(File batFile, {bool requiresElevation = false}) async* {
    try {
      final process = await Process.start(
        requiresElevation ? 'powershell' : 'cmd.exe',
        requiresElevation
            ? [
                '-Command',
                'Start-Process',
                'cmd.exe',
                '-ArgumentList',
                '"/c ${batFile.path}"',
                '-Verb',
                'RunAs',
                '-Wait'
              ]
            : ['/c', batFile.path],
        runInShell: true,
        mode: ProcessStartMode.normal,
      );

      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        yield line;
      }
      await for (final line in process.stderr.transform(utf8.decoder).transform(const LineSplitter())) {
        yield line;
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield 'Error: Batch file execution failed with exit code $exitCode';
      }
    } catch (e) {
      yield 'Error: Failed to execute batch file: $e';
    }
  }

  Stream<DependencyInstallStep> installDependency(String dependency) async* {
    final step = DependencyInstallStep(
      name: dependency,
      details: 'Preparing to install $dependency...',
      progress: 0.0,
    );

    yield step;

    try {
      final batFile = await _copyBatchFile(dependency);
      yield step.copyWith(
        details: 'Installing $dependency...',
        progress: 0.3,
        logs: 'Launching ${dependency}_install.bat...',
      );

      final outputStream = StreamController<String>();
      final processOutput = _runBatchFile(batFile, requiresElevation: dependency == 'python');

      await for (final log in processOutput) {
        outputStream.add(log);
        yield step.copyWith(
          details: 'Installing $dependency...',
          progress: 0.5,
          logs: log,
        );
      }

      final verifyCommand = dependency == 'python'
              ? ['python', '--version']
              : dependency == 'pip'
                  ? ['pip', '--version']
              : dependency == 'ffmpeg'
                  ? ['ffmpeg', '-version']
                  : dependency == 'faster-whisper'
                      ? ['pip', 'show', 'faster-whisper']
                      : dependency == 'libretranslate'
                      ? ['pip', 'show', 'libretranslate']
                      : [];

      final verifyProcess = await Process.run(
        verifyCommand.isNotEmpty ? verifyCommand[0] : '',
        verifyCommand.length > 1
            ? verifyCommand.sublist(1).map((e) => e.toString()).toList()
            : <String>[],
      );

      if (verifyProcess.exitCode == 0 && verifyProcess.stdout.toString().isNotEmpty) {
        // Extract version from pip show output if it's a Python package
        String versionInfo = '';
        if (dependency == 'faster-whisper' || dependency == 'libretranslate') {
          final versionLine = verifyProcess.stdout
              .toString()
              .split('\n')
              .firstWhere((line) => line.trim().startsWith('Version:'), orElse: () => '');
          versionInfo = versionLine.isNotEmpty ? ' ($versionLine.trim())' : '';
        }
        
        yield step.copyWith(
          details: '$dependency installed successfully$versionInfo',
          progress: 1.0,
          success: true,
          logs: '$dependency installation verified$versionInfo',
        );
      } else {
        throw Exception('$dependency verification failed: No version information found');
      }
    } catch (e) {
      yield step.copyWith(
        details: 'Failed to install $dependency: $e',
        progress: 0.0,
        error: e.toString(),
      );
      rethrow;
    } finally {
      await Future.delayed(const Duration(seconds: 1)); // Ensure logs are flushed
    }
  }
}