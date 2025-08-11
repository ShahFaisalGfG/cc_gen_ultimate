import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

import 'python_environment_service.dart';
import 'dependency_manager.dart';
import '../models/dependency_install_step.dart';

class ConfigurationService {
  static final ConfigurationService _instance =
      ConfigurationService._internal();
  factory ConfigurationService() => _instance;

  late final PythonEnvironmentService _pythonEnv;
  late final DependencyManager _dependencyManager;
  final _logger = Logger('ConfigurationService');

  ConfigurationService._internal() {
    _pythonEnv = PythonEnvironmentService();
    _dependencyManager = DependencyManager();
  }

  // Configuration file constants
  final String _configFileName = 'config.ini';
  String get _configDir => Platform.isAndroid
      ? '/storage/emulated/0/Android/data/com.example.cc_gen_ultimate/files'
      : (Platform.isWindows
            ? Directory
                  .current
                  .path // Use current directory for Windows
            : path.join(
                Platform.environment['HOME'] ?? '',
                '.cc_gen_ultimate',
              ));

  // Configuration keys
  final String keySelectedModel = 'selectedModel';
  final String keySelectedLanguage = 'selectedLanguage';
  final String keyOutputFormat = 'outputFormat';
  final String keyTranslateFrom = 'translateFrom';
  final String keyTranslateTo = 'translateTo';
  final String keyTheme = 'theme';
  final String keyMaxRetries = 'maxRetries';
  final String keyAutoExpandLogs = 'autoExpandLogs';

  // Default values
  final Map<String, dynamic> _defaults = {
    'selectedModel': 'tiny',
    'selectedLanguage': 'en',
    'outputFormat': '.srt',
    'translateFrom': 'en',
    'translateTo': 'none',
    'theme': 'system',
    'maxRetries': 3,
    'autoExpandLogs': true,
    'faster-whisper': {'downloadTimeout': 600, 'transcribeTimeout': 3600},
    'libretranslate': {'serverPort': 5000},
  };

  String get configPath => path.join(_configDir, _configFileName);

  String get fasterWhisperModelsDir =>
      path.join(_configDir, 'models', 'faster-whisper');
  String get translateModelsDir =>
      path.join(_configDir, 'models', 'libretranslate');

  // Configuration loading and saving
  Future<Map<String, dynamic>> loadConfiguration() async {
    try {
      final file = File(configPath);
      print('Config path: $configPath');
      print('Config file exists: ${await file.exists()}');

      if (!await file.exists()) {
        print('Creating default config...');
        await _saveConfig(_defaults);
        return Map<String, dynamic>.from(_defaults);
      }

      final iniContent = await file.readAsString();
      print('INI content: $iniContent');

      final config = _parseIniFile(iniContent);
      print('Parsed config: $config');

      return {..._defaults, ...config};
    } catch (e) {
      print('Error loading configuration: $e');
      _logger.warning('Error loading configuration: $e');
      return Map<String, dynamic>.from(_defaults);
    }
  }

  Map<String, dynamic> _parseIniFile(String iniContent) {
    final Map<String, dynamic> result = {};
    final lines = iniContent.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue; // Skip empty lines and comments
      }

      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();

        // Convert value to appropriate type
        if (value.toLowerCase() == 'true') {
          result[key] = true;
        } else if (value.toLowerCase() == 'false') {
          result[key] = false;
        } else if (int.tryParse(value) != null) {
          result[key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          result[key] = double.parse(value);
        } else {
          result[key] = value;
        }
      }
    }

    return result;
  }

  String _generateIniContent(Map<String, dynamic> config) {
    final buffer = StringBuffer();

    // Add a header comment
    buffer.writeln('# CC Gen Ultimate Configuration File');
    buffer.writeln('# Generated automatically - modify with care');
    buffer.writeln();

    // Write simple key-value pairs (exclude nested objects for now)
    config.forEach((key, value) {
      if (value is! Map) {
        buffer.writeln('$key=$value');
      }
    });

    return buffer.toString();
  }

  Future<void> _saveConfig(Map<String, dynamic> config) async {
    try {
      final configDir = Directory(_configDir);
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }

      final file = File(configPath);
      final iniContent = _generateIniContent(config);
      await file.writeAsString(iniContent);

      // Cache critical settings in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(
          keySelectedModel,
          config[keySelectedModel]?.toString() ??
              _defaults[keySelectedModel].toString(),
        ),
        prefs.setString(
          keySelectedLanguage,
          config[keySelectedLanguage] ?? _defaults[keySelectedLanguage],
        ),
        prefs.setString(
          keyOutputFormat,
          config[keyOutputFormat] ?? _defaults[keyOutputFormat],
        ),
      ]);
    } catch (e) {
      _logger.severe('Error saving configuration: $e');
      rethrow;
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final config = await loadConfiguration();
    config[key] = value;
    await _saveConfig(config);
  }

  Future<T?> getSetting<T>(String key) async {
    final config = await loadConfiguration();
    return config[key] as T?;
  }

  Future<void> saveModelConfig({
    required String modelName,
    required String language,
    required String outputFormat,
  }) async {
    try {
      final config = await loadConfiguration();
      config[keySelectedModel] = modelName;
      config[keySelectedLanguage] = language;
      config[keyOutputFormat] = outputFormat;
      await _saveConfig(config);
    } catch (e) {
      _logger.severe('Failed to save model configuration', e);
      rethrow;
    }
  }

  Future<Map<String, String>> getModelConfig() async {
    try {
      final config = await loadConfiguration();
      return {
        'modelName': config[keySelectedModel] as String,
        'language': config[keySelectedLanguage] as String,
        'outputFormat': config[keyOutputFormat] as String,
      };
    } catch (e) {
      return {
        'modelName': _defaults[keySelectedModel] as String,
        'language': _defaults[keySelectedLanguage] as String,
        'outputFormat': _defaults[keyOutputFormat] as String,
      };
    }
  }

  // Dependency checks
  Future<bool> isPythonInstalled() async {
    try {
      return await _pythonEnv.isPythonInstalled();
    } catch (e) {
      _logger.warning('Error checking Python installation: $e');
      return false;
    }
  }

  Future<Map<String, bool>> checkDependencies() async {
    try {
      return await _dependencyManager.getDependencyStatus();
    } catch (e) {
      _logger.warning('Error checking dependencies: $e');
      return {
        'python': false,
        'pip': false,
        'ffmpeg': false,
        'faster-whisper': false,
        'libre-translate': false,
      };
    }
  }

  Stream<DependencyInstallStep> installDependency(String dependency) {
    return _dependencyManager.installDependency(dependency);
  }

  Future<void> installDependencies() async {
    final status = await checkDependencies();
    for (var entry in status.entries) {
      if (!entry.value) {
        await for (var step in installDependency(entry.key)) {
          _logger.info('Installing ${entry.key}: ${step.details}');
          if (step.error != null) {
            _logger.severe('Failed to install ${entry.key}: ${step.error}');
            throw Exception(step.error);
          }
        }
      }
    }
  }
}

// Helper functions for platform-specific functionality
Future<void> requestAndroidPermissions() async {
  if (Platform.isAndroid) {
    await Permission.storage.request();
    await Permission.microphone.request();
    // Add more permissions as needed
  }
}

Future<void> runFFmpegCommandAndroid(String command) async {
  if (Platform.isAndroid) {
    await FFmpegKit.execute(command);
  }
}

// Python environment setup for Android (Chaquopy)
// 1. Add Chaquopy plugin to android/app/build.gradle:
//    plugins {
//      id 'com.chaquo.python'
//    }
// 2. Configure Chaquopy in android/app/build.gradle:
//    python {
//      buildPython "C:/path/to/python.exe" // Optional, for local builds
//      pip {
//        install "faster-whisper"
//        install "libretranslate"
//      }
//    }
// 3. Example Dart <-> Python communication via platform channel:
//
// import 'package:flutter/services.dart';
// const pythonChannel = MethodChannel('python_channel');
// Future<String> runPythonScript(String script) async {
//   return await pythonChannel.invokeMethod('runPython', {'script': script});
// }
//
// 4. Implement the corresponding Android code in MainActivity.kt or MainActivity.java
//    to execute Python scripts using Chaquopy.
