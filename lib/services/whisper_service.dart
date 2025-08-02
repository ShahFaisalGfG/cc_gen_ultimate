import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import '../models/whisper_model.dart';
import '../utils/process_utils.dart';
import 'exceptions.dart';

class WhisperService {
  static const String _whisperExecutable = 'faster-whisper';
  static final String _modelsDir = path.join(
    Platform.environment['APPDATA'] ?? '',
    'cc_gen_ultimate',
    'models',
    'faster-whisper'
  );
  
  static final _logger = Logger('WhisperService');
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  static Future<bool> isWhisperInstalled() async {
    try {
      final result = await Process.run(_whisperExecutable, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<List<WhisperModel>> getInstalledModels() async {
    final dir = Directory(_modelsDir);
    if (!await dir.exists()) return [];

    final List<WhisperModel> models = [];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.pt')) {
        final name = path.basenameWithoutExtension(entity.path);
        final size = await entity.length();
        models.add(WhisperModel(
          name: name,
          size: _formatSize(size),
          status: 'Completed',
        ));
      }
    }
    return models;
  }

  static Future<Map<String, String>> getSupportedLanguages() async {
    // Returns map of language code to language name
    return {
      'auto': 'Auto Detect',
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'nl': 'Dutch',
      'pl': 'Polish',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ar': 'Arabic',
      'hi': 'Hindi',
      // Add more languages as needed
    };
  }

  static Future<void> downloadModel(
    String modelName,
    void Function(double) onProgress,
    void Function(String) onStatus,
  ) async {
    final modelDir = Directory(_modelsDir);
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final modelPath = path.join(_modelsDir, '$modelName.pt');
    _logger.info('Starting download for model: $modelName');
    onStatus('Downloading model $modelName...');

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          _logger.info('Retry attempt $attempt for model: $modelName');
          onStatus('Retrying download... (Attempt $attempt of $_maxRetries)');
          await Future.delayed(_retryDelay);
        }

        final process = await Process.start(
          _whisperExecutable,
          ['--model', modelName, '--download-only'],
          workingDirectory: _modelsDir,
        );

        process.stdout.transform(ProcessUtils.progressExtractor()).listen(
          (progress) {
            onProgress(progress);
            _logger.fine('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
          onError: (error) {
            _logger.warning('Progress tracking error: $error');
            onStatus('Error tracking progress: $error');
          },
        );

        final exitCode = await process.exitCode;
        if (exitCode == 0) {
          _logger.info('Successfully downloaded model: $modelName');
          onStatus('Completed');
          return;
        } else {
          throw ModelDownloadException(
            'Process exited with code $exitCode',
            code: 'EXIT_CODE_$exitCode'
          );
        }
      } catch (e) {
        _logger.warning('Download attempt $attempt failed: $e');
        if (attempt == _maxRetries) {
          _logger.severe('All download attempts failed for model: $modelName');
          onStatus('Failed: Maximum retry attempts reached');
          throw ModelDownloadException(
            'Failed to download model after $_maxRetries attempts',
            originalError: e
          );
        }
      }
    }
  }

  static Future<void> transcribe({
    required String inputPath,
    required String modelName,
    required String language,
    required String outputFormat,
    required void Function(double) onProgress,
    required void Function(String) onStatus,
    required void Function(String) onLog,
  }) async {
    if (!await File(inputPath).exists()) {
      throw TranscriptionException('Input file does not exist: $inputPath');
    }

    final args = [
      inputPath,
      '--model', modelName,
      '--output_format', outputFormat.replaceAll('.', ''),
      if (language != 'auto') ...[
        '--language', language,
      ],
    ];

    _logger.info('Starting transcription for: ${path.basename(inputPath)}');
    _logger.fine('Transcription arguments: $args');
    onStatus('Processing');

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          _logger.info('Retry attempt $attempt for transcription');
          onStatus('Retrying transcription... (Attempt $attempt of $_maxRetries)');
          await Future.delayed(_retryDelay);
        }

        final process = await Process.start(_whisperExecutable, args);
        var hasProgress = false;
        var lastProgressUpdate = DateTime.now();
        
        process.stdout.transform(ProcessUtils.progressExtractor()).listen(
          (progress) {
            hasProgress = true;
            lastProgressUpdate = DateTime.now();
            onProgress(progress);
            _logger.fine('Transcription progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
          onError: (error) {
            _logger.warning('Progress tracking error: $error');
            onLog('Error tracking progress: $error');
          },
        );

        process.stderr.transform(ProcessUtils.logExtractor()).listen(
          (log) {
            _logger.fine('Faster Whisper output: $log');
            onLog(log);
          },
          onError: (error) {
            _logger.warning('Error reading process output: $error');
            onLog('Error: $error');
          },
        );

        // Monitor process health
        Timer.periodic(Duration(seconds: 30), (timer) {
          if (!hasProgress && DateTime.now().difference(lastProgressUpdate).inMinutes >= 5) {
            _logger.warning('No progress for 5 minutes, considering process stuck');
            process.kill();
            timer.cancel();
          }
        });

        final exitCode = await process.exitCode;
        if (exitCode == 0) {
          _logger.info('Successfully transcribed: ${path.basename(inputPath)}');
          onStatus('Completed');
          return;
        } else {
          throw TranscriptionException(
            'Process exited with code $exitCode',
            code: 'EXIT_CODE_$exitCode'
          );
        }
      } catch (e) {
        _logger.warning('Transcription attempt $attempt failed: $e');
        if (attempt == _maxRetries) {
          _logger.severe('All transcription attempts failed for: ${path.basename(inputPath)}');
          onStatus('Failed: Maximum retry attempts reached');
          throw TranscriptionException(
            'Failed to transcribe after $_maxRetries attempts',
            originalError: e
          );
        }
      }
    }
  }

  static Future<void> deleteModel(String modelName) async {
    final modelPath = path.join(_modelsDir, '$modelName.pt');
    final file = File(modelPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}
