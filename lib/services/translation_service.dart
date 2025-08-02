import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TranslationService {
  // Local LibreTranslate server URL
  static const String _serverUrl = 'http://127.0.0.1:5000';

  /// Get supported language pairs from LibreTranslate
  static Future<List<Map<String, String>>> getSupportedLanguagePairs() async {
    final response = await http.get(Uri.parse('$_serverUrl/languages'));
    if (response.statusCode == 200) {
      final List<dynamic> langs = json.decode(response.body);
      return langs.map((lang) => {
        'code': lang['code'] as String,
        'name': lang['name'] as String,
      }).toList();
    } else {
      throw Exception('Failed to fetch supported languages');
    }
  }

  /// Translate text using local LibreTranslate
  static Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/translate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'q': text,
        'source': from,
        'target': to,
        'format': 'text',
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translatedText'] as String;
    } else {
      throw Exception('Translation failed: ${response.body}');
    }
  }

  /// Start local LibreTranslate server (Python/Chaquopy or subprocess)
  static Future<void> startLocalServer() async {
    if (Platform.isAndroid) {
      // Use Chaquopy to run Python server
      // Example: await runPythonScript('import subprocess; subprocess.Popen(["python", "libretranslate-server.py"])');
    } else if (Platform.isWindows) {
      // Use subprocess to run Python server
      await Process.start('python', ['libretranslate-server.py']);
    }
  }
}
