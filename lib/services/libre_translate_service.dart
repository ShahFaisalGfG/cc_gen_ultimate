import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/translation_request.dart';
import 'configuration_service.dart';
import 'exceptions.dart';

class LibreTranslateService {
  static final LibreTranslateService _instance = LibreTranslateService._internal();
  factory LibreTranslateService() => _instance;

  final _logger = Logger('LibreTranslateService');
  final _config = ConfigurationService();
  Process? _serverProcess;
  final String _baseUrl = 'http://localhost:5000';

  LibreTranslateService._internal();

  Future<void> startServer() async {
    if (_serverProcess != null) {
      _logger.info('Server already running');
      return;
    }

    final config = await _config.loadConfiguration();
    final modelPath = config['libreTranslateModel'] as String?;
    
    if (modelPath == null || !await File(modelPath).exists()) {
      throw ServiceException(
        'LibreTranslate model not found. Please download it first.',
        'MODEL_NOT_FOUND'
      );
    }

    try {
      _serverProcess = await Process.start(
        'libretranslate',
        ['--host', 'localhost', '--port', '5000', '--model-path', modelPath],
      );

      _serverProcess!.stdout.listen((data) {
        final output = utf8.decode(data);
        _logger.fine('LibreTranslate: $output');
      });

      _serverProcess!.stderr.listen((data) {
        final error = utf8.decode(data);
        _logger.warning('LibreTranslate Error: $error');
      });

      // Wait for server to start
      await _waitForServer();
      _logger.info('LibreTranslate server started successfully');
    } catch (e) {
      throw ServiceException(
        'Failed to start LibreTranslate server: $e',
        'SERVER_START_FAILED'
      );
    }
  }

  Future<void> stopServer() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
      _logger.info('LibreTranslate server stopped');
    }
  }

  Future<bool> isServerRunning() async {
    if (_serverProcess == null) return false;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/languages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
          .map((lang) => lang['code'].toString())
          .toList();
      }
      throw ServiceException(
        'Failed to get supported languages: ${response.statusCode}',
        'LANGUAGES_FETCH_FAILED'
      );
    } catch (e) {
      throw ServiceException(
        'Failed to get supported languages: $e',
        'LANGUAGES_FETCH_FAILED'
      );
    }
  }

  Future<void> translate({
    required String filePath,
    required String fromLang,
    required String toLang,
    required Function(String) onLog,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    if (!await isServerRunning()) {
      await startServer();
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ServiceException('File not found: $filePath', 'FILE_NOT_FOUND');
      }

      onStatus('Processing');
      onLog('Starting translation from $fromLang to $toLang: $filePath');

      // Read the subtitle file
      final content = await file.readAsString();
      final lines = content.split('\n');
      final totalLines = lines.length;
      var processedLines = 0;

      // Process subtitle file in chunks for better performance
      final translatedLines = <String>[];
      final chunkSize = 10;
      
      for (var i = 0; i < lines.length; i += chunkSize) {
        final chunk = lines.skip(i).take(chunkSize).join('\n');
        
        final request = TranslationRequest(
          text: chunk,
          source: fromLang,
          target: toLang,
        );

        final response = await _translateText(request);
        translatedLines.add(response.translatedText);
        
        processedLines += chunkSize;
        final progress = (processedLines / totalLines).clamp(0.0, 1.0);
        onProgress(progress);
        onLog('Translation progress: ${(progress * 100).toInt()}%');
      }

      // Save the translated file
      final outputPath = filePath.replaceAll(
        RegExp(r'\.[^/.]+$'),
        '_$toLang.srt'
      );
      await File(outputPath).writeAsString(translatedLines.join('\n'));
      
      onStatus('Completed');
      onLog('Translation completed successfully: $outputPath');
    } catch (e) {
      onStatus('Failed');
      onLog('Translation failed: $e');
      rethrow;
    }
  }

  Future<TranslationResponse> _translateText(TranslationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return TranslationResponse.fromJson(json.decode(response.body));
      }

      throw ServiceException(
        'Translation failed: ${response.statusCode}\n${response.body}',
        'TRANSLATION_FAILED'
      );
    } catch (e) {
      throw ServiceException(
        'Translation failed: $e',
        'TRANSLATION_FAILED'
      );
    }
  }

  Future<void> _waitForServer() async {
    for (var i = 0; i < 30; i++) {
      if (await isServerRunning()) {
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    throw ServiceException(
      'Timeout waiting for LibreTranslate server to start',
      'SERVER_TIMEOUT'
    );
  }

  Future<void> downloadModel({
    required String language,
    required Function(double) onProgress,
    required Function(String) onStatus,
  }) async {
    try {
      onStatus('Starting download');
      
      // TODO: Implement model download from official source
      // This will need to:
      // 1. Get the download URL for the requested language model
      // 2. Download the model file with progress reporting
      // 3. Verify the downloaded file
      // 4. Update configuration with the new model path

      throw UnimplementedError('Model download not yet implemented');
    } catch (e) {
      onStatus('Failed');
      throw ServiceException(
        'Failed to download translation model: $e',
        'MODEL_DOWNLOAD_FAILED'
      );
    }
  }
}
