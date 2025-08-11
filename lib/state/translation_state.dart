import 'package:flutter/foundation.dart';
import '../models/queued_file.dart';
import '../services/ai/libre_translate_service.dart';
import '../services/core/configuration_service.dart';
import '../utils/file_utils.dart';

class TranslationState extends ChangeNotifier {
  final List<QueuedFile> _queue = [];
  final List<String> _logs = [];
  bool _isProcessing = false;
  String _fromLanguage = 'en';
  String _toLanguage = 'es';
  String _outputFormat = 'srt';
  Map<String, String> _supportedLanguages = {};
  
  final LibreTranslateService _translateService = LibreTranslateService();
  final ConfigurationService _configService = ConfigurationService();

  // Getters
  List<QueuedFile> get queue => _queue;
  List<String> get logs => _logs;
  bool get isProcessing => _isProcessing;
  String get fromLanguage => _fromLanguage;
  String get toLanguage => _toLanguage;
  String get outputFormat => _outputFormat;
  Map<String, String> get supportedLanguages => _supportedLanguages;

  TranslationState() {
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _loadConfiguration();
    await _loadSupportedLanguages();
    notifyListeners();
  }

  Future<void> _loadConfiguration() async {
    final config = await _configService.loadConfiguration();
    _fromLanguage = config['translateFromLang'] ?? 'en';
    _toLanguage = config['translateToLang'] ?? 'es';
    _outputFormat = config['translateOutputFormat'] ?? 'srt';
  }

  Future<void> _loadSupportedLanguages() async {
    try {
      if (!await _translateService.isServerRunning()) {
        await _translateService.startServer();
      }
      final languages = await _translateService.getSupportedLanguages();
      _supportedLanguages = {
        for (var code in languages)
          code: _getLanguageName(code)
      };
    } catch (e) {
      _logs.add('Error loading languages: $e');
    }
    notifyListeners();
  }

  String _getLanguageName(String code) {
    // This is a basic mapping, should be expanded
    const Map<String, String> languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
    };
    return languageNames[code] ?? code;
  }

  void addFiles(List<String> filePaths) {
    for (var path in filePaths) {
      if (!_queue.any((file) => file.name == path)) {
        _queue.add(QueuedFile(
          name: path,
          status: 'Waiting',
          progress: null,
        ));
        _logs.add('Added file to translate: $path');
      }
    }
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _logs.add('Translation queue cleared');
    notifyListeners();
  }

  void removeCompleted() {
    _queue.removeWhere((file) => 
      file.status == 'Completed' || file.status == 'Failed'
    );
    _logs.add('Removed completed/failed files from queue');
    notifyListeners();
  }

  void retryFailed() {
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].status == 'Failed') {
        _queue[i] = QueuedFile(
          name: _queue[i].name,
          status: 'Waiting',
          progress: null,
        );
      }
    }
    _logs.add('Reset failed translations for retry');
    notifyListeners();
  }

  Future<void> startTranslation() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _logs.add('Starting translation queue...');
    notifyListeners();

    try {
      if (!await _translateService.isServerRunning()) {
        await _translateService.startServer();
        _logs.add('Started translation server');
      }

      for (var i = 0; i < _queue.length; i++) {
        if (_queue[i].status == 'Completed' || _queue[i].status == 'Failed') {
          continue;
        }

        _updateQueueItem(i, 'Processing', 0.0);

        try {
          await _translateService.translate(
            filePath: _queue[i].name,
            fromLang: _fromLanguage,
            toLang: _toLanguage,
            onProgress: (progress) => _updateQueueItem(i, 'Processing', progress),
            onStatus: (status) {
              if (status == 'Completed') {
                final outputPath = FileUtils.getTranslatedCCPath(
                  _queue[i].name, 
                  _outputFormat,
                  _toLanguage
                );
                _logs.add('Translated CC saved: $outputPath');
              }
              _updateQueueItem(i, status, status == 'Completed' ? 1.0 : null);
            },
            onLog: (log) => _addLog(log),
          );
        } catch (e) {
          _logs.add('Translation error: $e');
          _updateQueueItem(i, 'Failed', null);
        }
      }
    } finally {
      _isProcessing = false;
      _logs.add('Translation queue finished');
      notifyListeners();
    }
  }

  void _updateQueueItem(int index, String status, double? progress) {
    _queue[index] = QueuedFile(
      name: _queue[index].name,
      status: status,
      progress: progress,
    );
    notifyListeners();
  }

  void _addLog(String log) {
    _logs.add(log);
    notifyListeners();
  }

  Future<void> setFromLanguage(String language) async {
    _fromLanguage = language;
    await _configService.updateSetting('translateFromLang', language);
    notifyListeners();
  }

  Future<void> setToLanguage(String language) async {
    _toLanguage = language;
    await _configService.updateSetting('translateToLang', language);
    notifyListeners();
  }

  Future<void> setOutputFormat(String format) async {
    _outputFormat = format;
    await _configService.updateSetting('translateOutputFormat', format);
    notifyListeners();
  }

  @override
  void dispose() {
    _translateService.stopServer();
    super.dispose();
  }
}
