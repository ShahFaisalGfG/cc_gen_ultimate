import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:cc_gen_ultimate/models/model_info.dart';
import 'package:logging/logging.dart';

class _DownloadCancelledException implements Exception {
  String get message => 'Download was cancelled';
  @override
  String toString() => message;
}

class ModelService {
  static final _logger = Logger('ModelService');
  
  // Base URLs for model downloads
  static const _whisperBaseUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/';
  static const _libreTranslateBaseUrl = 'https://github.com/LibreTranslate/models/releases/download/v2.3.1/';
  
  // Singleton instance
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  final _modelStatusController = StreamController<List<ModelInfo>>.broadcast();
  Stream<List<ModelInfo>> get modelStatusStream => _modelStatusController.stream;
  
  Object? _currentDownload;

  // Predefined model configurations
  // All supported languages for LibreTranslate
  static final List<String> _libreTranslateLanguages = [
    'en', 'sq', 'ar', 'az', 'eu', 'bn', 'bg', 'ca', 'zh-Hans', 'zh-Hant',
    'cs', 'da', 'nl', 'eo', 'et', 'fi', 'fr', 'gl', 'de', 'el',
    'he', 'hi', 'hu', 'id', 'ga', 'it', 'ja', 'ko', 'ky', 'lv',
    'lt', 'ms', 'nb', 'fa', 'pl', 'pt', 'pt-BR', 'ro', 'ru', 'sr',
    'sk', 'sl', 'es', 'sv', 'tl', 'th', 'tr', 'uk', 'ur', 'vi'
  ];

  static final Map<String, String> _languageNames = {
    'en': 'English', 'sq': 'Albanian', 'ar': 'Arabic', 'az': 'Azerbaijani',
    'eu': 'Basque', 'bn': 'Bengali', 'bg': 'Bulgarian', 'ca': 'Catalan',
    'zh-Hans': 'Chinese', 'zh-Hant': 'Chinese (traditional)', 'cs': 'Czech',
    'da': 'Danish', 'nl': 'Dutch', 'eo': 'Esperanto', 'et': 'Estonian',
    'fi': 'Finnish', 'fr': 'French', 'gl': 'Galician', 'de': 'German',
    'el': 'Greek', 'he': 'Hebrew', 'hi': 'Hindi', 'hu': 'Hungarian',
    'id': 'Indonesian', 'ga': 'Irish', 'it': 'Italian', 'ja': 'Japanese',
    'ko': 'Korean', 'ky': 'Kyrgyz', 'lv': 'Latvian', 'lt': 'Lithuanian',
    'ms': 'Malay', 'nb': 'Norwegian', 'fa': 'Persian', 'pl': 'Polish',
    'pt': 'Portuguese', 'pt-BR': 'Portuguese (Brazil)', 'ro': 'Romanian',
    'ru': 'Russian', 'sr': 'Serbian', 'sk': 'Slovak', 'sl': 'Slovenian',
    'es': 'Spanish', 'sv': 'Swedish', 'tl': 'Tagalog', 'th': 'Thai',
    'tr': 'Turkish', 'uk': 'Ukrainian', 'ur': 'Urdu', 'vi': 'Vietnamese'
  };

  // LibreTranslate models map - one model per language
  static Map<String, ModelInfo> get _libreTranslateModels {
    Map<String, ModelInfo> models = {};
    
    for (String langCode in _libreTranslateLanguages) {
      String langName = _languageNames[langCode] ?? langCode;
      models[langCode] = ModelInfo(
        name: langCode,
        type: ModelType.libreTranslate,
        version: 'v2.3.1',
        sizeInMB: 85, // Average size per language model
        vramRequiredMB: 512, // Reduced requirements for single language
        supportedLanguages: [langCode],
        capabilities: 'Neural machine translation for $langName',
        status: ModelStatus.available,
      );
    }
    
    return models;
  }

  static final Map<String, ModelInfo> _whisperModels = {
    // Multilingual Models
    'tiny': ModelInfo(
      name: 'tiny',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 39,
      vramRequiredMB: 1024,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, ~10x faster than large, basic accuracy',
      status: ModelStatus.available,
    ),
    'base': ModelInfo(
      name: 'base',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 74,
      vramRequiredMB: 1024,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, ~7x faster than large, improved accuracy',
      status: ModelStatus.available,
    ),
    'small': ModelInfo(
      name: 'small',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 244,
      vramRequiredMB: 2048,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, ~4x faster than large, good accuracy',
      status: ModelStatus.available,
    ),
    'medium': ModelInfo(
      name: 'medium',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 769,
      vramRequiredMB: 5120,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, ~2x faster than large, high accuracy',
      status: ModelStatus.available,
    ),
    'large': ModelInfo(
      name: 'large',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 1550,
      vramRequiredMB: 10240,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, best accuracy, baseline speed',
      status: ModelStatus.available,
    ),
    'turbo': ModelInfo(
      name: 'turbo',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 809,
      vramRequiredMB: 6144,
      supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'ja', 'zh', 'ko', 'ru', 'hi', 'tr', 'pl', 'ar', 'hu', 'vi', 'sv', 'da', 'fi', 'id'],
      capabilities: 'Multilingual, ~8x faster than large, optimized for speed',
      status: ModelStatus.available,
    ),

    // English-only Models
    'tiny.en': ModelInfo(
      name: 'tiny.en',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 39,
      vramRequiredMB: 1024,
      supportedLanguages: ['en'],
      capabilities: 'English-only, ~10x faster than large, basic accuracy',
      status: ModelStatus.available,
    ),
    'base.en': ModelInfo(
      name: 'base.en',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 74,
      vramRequiredMB: 1024,
      supportedLanguages: ['en'],
      capabilities: 'English-only, ~7x faster than large, improved accuracy',
      status: ModelStatus.available,
    ),
    'small.en': ModelInfo(
      name: 'small.en',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 244,
      vramRequiredMB: 2048,
      supportedLanguages: ['en'],
      capabilities: 'English-only, ~4x faster than large, good accuracy',
      status: ModelStatus.available,
    ),
    'medium.en': ModelInfo(
      name: 'medium.en',
      type: ModelType.whisperAI,
      version: 'v3',
      sizeInMB: 769,
      vramRequiredMB: 5120,
      supportedLanguages: ['en'],
      capabilities: 'English-only, ~2x faster than large, high accuracy',
      status: ModelStatus.available,
    ),
  };

  String getLanguageName(String code) {
    return _languageNames[code] ?? code;
  }

  List<ModelInfo> getAvailableModels(ModelType type) {
    switch (type) {
      case ModelType.whisperAI:
        return _whisperModels.values.toList();
      case ModelType.libreTranslate:
        return _libreTranslateModels.values.toList();
    }
  }

  Future<void> downloadModel(String modelName) async {
    final model = _whisperModels[modelName];
    if (model == null) {
      _logger.warning('Model $modelName not found');
      return;
    }

    // Check if already downloaded
    if (model.status == ModelStatus.downloaded) {
      _logger.info('Model $modelName is already downloaded');
      return;
    }

    // Update model status to downloading
    final updatedModel = ModelInfo(
      name: model.name,
      type: model.type,
      version: model.version,
      sizeInMB: model.sizeInMB,
      vramRequiredMB: model.vramRequiredMB,
      supportedLanguages: model.supportedLanguages,
      capabilities: model.capabilities,
      status: ModelStatus.downloading,
      downloadProgress: 0,
      downloadSpeed: 0,
    );

    _whisperModels[modelName] = updatedModel;
    _modelStatusController.add(getAvailableModels(ModelType.whisperAI));

    // Real implementation with cancellation support
    final downloadToken = _currentDownload = Object();
    final modelUrl = await _getModelDownloadUrl(modelName);
    final savePath = await _getModelPath(modelName);
    
    try {
      // Create directories if needed
      final saveDir = Directory(path.dirname(savePath));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Start download
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await client.send(request);
      
      // Open file for writing
      final file = File(savePath);
      final sink = file.openWrite();
      
      final totalBytes = response.contentLength ?? -1;
      var receivedBytes = 0;
      var lastProgressUpdate = DateTime.now();
      var lastBytesReceived = 0;

      try {
        await for (final chunk in response.stream) {
          if (_currentDownload != downloadToken) {
            throw _DownloadCancelledException();
          }

          receivedBytes += chunk.length;
          sink.add(chunk);

          // Update progress every 100ms
          final now = DateTime.now();
          if (now.difference(lastProgressUpdate) >= Duration(milliseconds: 100)) {
            final duration = now.difference(lastProgressUpdate).inSeconds;
            final bytesPerSecond = duration > 0 
              ? (receivedBytes - lastBytesReceived) / duration 
              : 0;
            final progress = totalBytes > 0 ? (receivedBytes / totalBytes * 100) : 0.0;
            
            final progressModel = ModelInfo(
              name: model.name,
              type: model.type,
              version: model.version,
              sizeInMB: model.sizeInMB,
              vramRequiredMB: model.vramRequiredMB,
              supportedLanguages: model.supportedLanguages,
              capabilities: model.capabilities,
              status: ModelStatus.downloading,
              downloadProgress: progress,
              downloadSpeed: bytesPerSecond / (1024 * 1024), // Convert to MB/s
            );
            
            _whisperModels[modelName] = progressModel;
            _modelStatusController.add(getAvailableModels(ModelType.whisperAI));
            
            lastProgressUpdate = now;
            lastBytesReceived = receivedBytes;
          }
        }

        // Download complete
        await sink.close();
        final downloadedModel = ModelInfo(
          name: model.name,
          type: model.type,
          version: model.version,
          sizeInMB: model.sizeInMB,
          vramRequiredMB: model.vramRequiredMB,
          supportedLanguages: model.supportedLanguages,
          capabilities: model.capabilities,
          status: ModelStatus.downloaded,
          lastUsed: null,
          isVerified: false,
        );

        _whisperModels[modelName] = downloadedModel;
        _modelStatusController.add(getAvailableModels(ModelType.whisperAI));
      } catch (e) {
        await sink.close();
        await file.delete();
        rethrow;
      } finally {
        client.close();
      }
    } on _DownloadCancelledException {
      _logger.info('Download cancelled for model: $modelName');
      final cancelledModel = ModelInfo(
        name: model.name,
        type: model.type,
        version: model.version,
        sizeInMB: model.sizeInMB,
        vramRequiredMB: model.vramRequiredMB,
        supportedLanguages: model.supportedLanguages,
        capabilities: model.capabilities,
        status: ModelStatus.available,
      );
      _whisperModels[modelName] = cancelledModel;
      _modelStatusController.add(getAvailableModels(ModelType.whisperAI));
    } catch (e) {
      _logger.severe('Error downloading model $modelName: $e');
      rethrow;
    }

    final downloadedModel = ModelInfo(
      name: model.name,
      type: model.type,
      version: model.version,
      sizeInMB: model.sizeInMB,
      vramRequiredMB: model.vramRequiredMB,
      supportedLanguages: model.supportedLanguages,
      capabilities: model.capabilities,
      status: ModelStatus.downloaded,
      lastUsed: DateTime.now(),
      isVerified: true,
    );

    _whisperModels[modelName] = downloadedModel;
    _modelStatusController.add(getAvailableModels(ModelType.whisperAI));
  }

  Future<void> deleteModel(String modelName) async {
    final model = _whisperModels[modelName];
    if (model == null) {
      _logger.warning('Model $modelName not found');
      return;
    }

    // TODO: Implement actual delete logic
    final updatedModel = ModelInfo(
      name: model.name,
      type: model.type,
      version: model.version,
      sizeInMB: model.sizeInMB,
      vramRequiredMB: model.vramRequiredMB,
      supportedLanguages: model.supportedLanguages,
      capabilities: model.capabilities,
      status: ModelStatus.available,
    );

    _whisperModels[modelName] = updatedModel;
    _modelStatusController.add(getAvailableModels(ModelType.whisperAI));
  }

  void cancelDownload(String modelName) {
    _currentDownload = null;
  }

  Future<void> verifyModel(String modelName) async {
    final model = _whisperModels[modelName];
    if (model == null) {
      _logger.warning('Model $modelName not found');
      return;
    }

    if (model.status != ModelStatus.downloaded) {
      _logger.warning('Cannot verify model $modelName: not downloaded');
      return;
    }

    try {
      _logger.info('Verifying model: $modelName');
      
      final modelPath = await _getModelPath(modelName);
      if (!await File(modelPath).exists()) {
        throw Exception('Model file not found');
      }

      // Calculate hash and verify
      final hash = await _calculateModelHash(modelPath);
      final isValid = await _verifyModelHash(modelName, hash);
      
      final verifiedModel = ModelInfo(
        name: model.name,
        type: model.type,
        version: model.version,
        sizeInMB: model.sizeInMB,
        vramRequiredMB: model.vramRequiredMB,
        supportedLanguages: model.supportedLanguages,
        capabilities: model.capabilities,
        status: model.status,
        lastUsed: model.lastUsed,
        isVerified: isValid,
      );

      _whisperModels[modelName] = verifiedModel;
      _modelStatusController.add(getAvailableModels(ModelType.whisperAI));

      if (!isValid) {
        _logger.warning('Model verification failed: $modelName');
        throw Exception('Model verification failed');
      }
    } catch (e) {
      _logger.severe('Error verifying model $modelName: $e');
      rethrow;
    }
  }

  Future<String> _calculateModelHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (e) {
      _logger.severe('Error calculating model hash: $e');
      rethrow;
    }
  }

  Future<bool> _verifyModelHash(String modelName, String actualHash) async {
    try {
      // In a real implementation, fetch the expected hash from a secure source
      final expectedHash = await _getExpectedHash(modelName);
      return expectedHash == actualHash;
    } catch (e) {
      _logger.severe('Error verifying model hash: $e');
      return false;
    }
  }

  Future<String> _getExpectedHash(String modelName) async {
    // TODO: Implement fetching expected hash from a secure source
    return 'dummy-hash';
  }

  Future<String> _getModelPath(String modelName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'models', modelName);
  }

  Future<String> _getModelDownloadUrl(String modelName) async {
    final model = _whisperModels[modelName];
    if (model == null) {
      throw Exception('Model not found: $modelName');
    }

    switch (model.type) {
      case ModelType.whisperAI:
        return '$_whisperBaseUrl$modelName.bin';
      case ModelType.libreTranslate:
        return '$_libreTranslateBaseUrl$modelName.argos';
    }
  }

  void dispose() {
    _modelStatusController.close();
  }
}
