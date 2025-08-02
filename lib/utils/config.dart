import 'package:shared_preferences/shared_preferences.dart';

class ConfigManager {
  static Future<Map<String, dynamic>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'selectedModel': prefs.getString('selectedModel') ?? 'tiny',
      'selectedLanguage': prefs.getString('selectedLanguage') ?? 'English',
      'translateFrom': prefs.getString('translateFrom') ?? 'English',
      'translateTo': prefs.getString('translateTo') ?? 'None',
      'selectedFormat': prefs.getString('selectedFormat') ?? '.srt',
      'themeMode': prefs.getInt('themeMode') ?? 2,
    };
  }

  static Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedModel', config['selectedModel']);
    await prefs.setString('selectedLanguage', config['selectedLanguage']);
    await prefs.setString('translateFrom', config['translateFrom']);
    await prefs.setString('translateTo', config['translateTo']);
    await prefs.setString('selectedFormat', config['selectedFormat']);
    await prefs.setInt('themeMode', config['themeMode']);
  }
}
