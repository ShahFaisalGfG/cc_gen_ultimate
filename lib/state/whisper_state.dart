import 'package:flutter/foundation.dart';
import '../models/whisper_model.dart';
import '../services/ai/whisper_service.dart';
import '../services/core/configuration_service.dart';

class WhisperState extends ChangeNotifier {
  List<WhisperModel> _installedModels = [];
  final List<WhisperModel> _downloadingModels = [];
  Map<String, String> _supportedLanguages = {};
  bool _isProcessing = false;
  String _selectedModel = 'tiny';
  String _selectedLanguage = 'en';
  String _outputFormat = 'srt';
  
  final ConfigurationService _configService = ConfigurationService();

  // Getters
  List<WhisperModel> get installedModels => _installedModels;
  List<WhisperModel> get downloadingModels => _downloadingModels;
  Map<String, String> get supportedLanguages => _supportedLanguages;
  bool get isProcessing => _isProcessing;
  String get selectedModel => _selectedModel;
  String get selectedLanguage => _selectedLanguage;
  String get outputFormat => _outputFormat;

  WhisperState() {
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _loadConfiguration();
    await _loadInstalledModels();
    await _loadSupportedLanguages();
    notifyListeners();
  }

  Future<void> _loadConfiguration() async {
    final config = await _configService.loadConfiguration();
    _selectedModel = config['selectedModel'] ?? 'tiny';
    _selectedLanguage = config['selectedLanguage'] ?? 'en';
    _outputFormat = config['outputFormat'] ?? 'srt';
  }

  Future<void> _loadInstalledModels() async {
    _installedModels = await WhisperService.getInstalledModels();
    notifyListeners();
  }

  Future<void> _loadSupportedLanguages() async {
    _supportedLanguages = await WhisperService.getSupportedLanguages();
    notifyListeners();
  }

  // Model Management
  Future<void> downloadModel(String modelName) async {
    final model = WhisperModel(
      name: modelName,
      size: 'Downloading...',
      status: 'Waiting',
    );
    _downloadingModels.add(model);
    notifyListeners();

    try {
      await WhisperService.downloadModel(
        modelName,
        (progress) {
          final index = _downloadingModels.indexWhere((m) => m.name == modelName);
          if (index != -1) {
            _downloadingModels[index] = model.copyWith(
              progress: progress,
              status: 'Downloading',
            );
            notifyListeners();
          }
        },
        (status) {
          final index = _downloadingModels.indexWhere((m) => m.name == modelName);
          if (index != -1) {
            if (status == 'Completed') {
              _downloadingModels.removeAt(index);
              _loadInstalledModels(); // Refresh installed models
            } else {
              _downloadingModels[index] = model.copyWith(status: status);
            }
            notifyListeners();
          }
        },
      );
    } catch (e) {
      final index = _downloadingModels.indexWhere((m) => m.name == modelName);
      if (index != -1) {
        _downloadingModels[index] = model.copyWith(status: 'Failed');
        notifyListeners();
      }
    }
  }

  Future<void> deleteModel(String modelName) async {
    await WhisperService.deleteModel(modelName);
    await _loadInstalledModels();
  }

  // Settings Management
  Future<void> setModel(String modelName) async {
    _selectedModel = modelName;
    await _configService.updateSetting('selectedModel', modelName);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await _configService.updateSetting('selectedLanguage', language);
    notifyListeners();
  }

  Future<void> setOutputFormat(String format) async {
    _outputFormat = format;
    await _configService.updateSetting('outputFormat', format);
    notifyListeners();
  }

  // Processing State
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }
}
