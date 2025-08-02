import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/whisper_model.dart';
import '../services/whisper_service.dart';
import '../services/dependency_manager.dart';

class WhisperController extends ChangeNotifier {
  final _logger = Logger('WhisperController');
  final _dependencyManager = DependencyManager();
  
  // Stream controllers for UI updates
  final _installedModelsController = StreamController<List<WhisperModel>>.broadcast();
  final _logController = StreamController<String>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  // Streams exposed to UI
  Stream<List<WhisperModel>> get installedModels => _installedModelsController.stream;
  Stream<String> get logStream => _logController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;

  // UI state variables
  List<WhisperModel> get downloadQueue => List.unmodifiable(_downloadQueue);
  bool get hasDownloads => _downloadQueue.isNotEmpty;

  // State variables
  final List<WhisperModel> _downloadQueue = [];
  bool _isProcessing = false;
  String _currentStatus = '';
  String _selectedModel = 'tiny';
  String _selectedLanguage = 'auto';
  String _outputFormat = '.srt';

  // Getters
  bool get isProcessing => _isProcessing;
  String get currentStatus => _currentStatus;
  String get selectedModel => _selectedModel;
  String get selectedLanguage => _selectedLanguage;
  String get outputFormat => _outputFormat;

  Future<void> initialize() async {
    try {
      _log('Initializing Whisper service...');
      
      // Check dependencies
      final status = await _dependencyManager.getDependencyStatus();
      if (!status['python']!) {
        throw Exception('Python is not installed');
      }
      if (!status['faster-whisper']!) {
        _log('Installing Faster Whisper...');
        await for (final step in _dependencyManager.installDependency('faster-whisper')) {
          _log(step.details);
          _updateProgress(step.progress ?? 0.0);
          _updateStatus(step.logs ?? step.details);
          if (step.error != null) {
            throw Exception(step.error);
          }
        }
      }

      await _refreshInstalledModels();
      
      _log('Whisper service initialized successfully');
    } catch (e) {
      _log('Error initializing Whisper service: $e');
      rethrow;
    }
  }

  Future<void> _refreshInstalledModels() async {
    try {
      final models = await WhisperService.getInstalledModels();
      _installedModelsController.add(models);
      notifyListeners();
    } catch (e) {
      _log('Error refreshing models: $e');
    }
  }

  Future<void> downloadModel(String modelName) async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      notifyListeners();

      final model = WhisperModel(
        name: modelName,
        size: 'Downloading...',
        status: 'Pending'
      );
      _downloadQueue.add(model);

      await WhisperService.downloadModel(
        modelName,
        (progress) {
          _updateProgress(progress);
          final modelIndex = _downloadQueue.indexOf(model);
          if (modelIndex != -1) {
            final updatedModel = model.copyWith(
              status: 'Downloading: ${(progress * 100).toStringAsFixed(1)}%'
            );
            _downloadQueue[modelIndex] = updatedModel;
            notifyListeners();
          }
        },
        (status) {
          _updateStatus(status);
          final modelIndex = _downloadQueue.indexOf(model);
          if (modelIndex != -1) {
            final updatedModel = model.copyWith(status: status);
            _downloadQueue[modelIndex] = updatedModel;
            notifyListeners();
          }
        },
      );

      await _refreshInstalledModels();
      _downloadQueue.remove(model);
    } catch (e) {
      _log('Error downloading model: $e');
      _updateStatus('Failed to download model');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> transcribe(String inputPath) async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      notifyListeners();

      await WhisperService.transcribe(
        inputPath: inputPath,
        modelName: _selectedModel,
        language: _selectedLanguage,
        outputFormat: _outputFormat,
        onProgress: _updateProgress,
        onStatus: _updateStatus,
        onLog: _log,
      );
    } catch (e) {
      _log('Error during transcription: $e');
      _updateStatus('Transcription failed');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Setters for configuration
  void setSelectedModel(String modelName) {
    _selectedModel = modelName;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setOutputFormat(String format) {
    _outputFormat = format;
    notifyListeners();
  }


  // Utility methods for UI updates
  void _log(String message) {
    _logger.info(message);
    _logController.add(message);
  }

  void _updateProgress(double progress) {
    _progressController.add(progress);
  }

  void _updateStatus(String status) {
    _currentStatus = status;
    _statusController.add(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _installedModelsController.close();
    _logController.close();
    _progressController.close();
    _statusController.close();
    super.dispose();
  }

  Future<bool> isWhisperInstalled() async {
    return WhisperService.isWhisperInstalled();
  }

  Future<Map<String, String>> getSupportedLanguages() async {
    return WhisperService.getSupportedLanguages();
  }

  // ...existing code...
}
