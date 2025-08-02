import 'dart:io';

class Preferences {
  static final String configPath = 'config.ini';

  static Future<Map<String, String>> loadPreferences() async {
    final file = File(configPath);
    if (!await file.exists()) return {};
    final lines = await file.readAsLines();
    final prefs = <String, String>{};
    for (var line in lines) {
      if (line.contains('=')) {
        final parts = line.split('=');
        prefs[parts[0].trim()] = parts[1].trim();
      }
    }
    return prefs;
  }

  static Future<void> savePreferences(Map<String, String> prefs) async {
    final file = File(configPath);
    final content = prefs.entries.map((e) => '${e.key}=${e.value}').join('\n');
    await file.writeAsString(content);
  }
}
