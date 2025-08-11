import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';
import '../data/cache_manager.dart';
import '../shared/exceptions.dart';

class UpdateManager {
  static const String _updateManifestUrl = 'https://api.github.com/repos/ShahFaisalGFG/cc_gen_ultimate/releases/latest';
  static const String _resourcesManifestUrl = 'https://raw.githubusercontent.com/ShahFaisalGFG/cc_gen_ultimate/main/resources.json';

  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(Uri.parse(_updateManifestUrl));
      
      if (response.statusCode == 200) {
        final releaseInfo = json.decode(response.body);
        final latestVersion = releaseInfo['tag_name'].toString().replaceAll('v', '');
        final currentVersion = packageInfo.version;

        return {
          'hasUpdate': _compareVersions(latestVersion, currentVersion) > 0,
          'currentVersion': currentVersion,
          'latestVersion': latestVersion,
          'releaseNotes': releaseInfo['body'],
          'downloadUrl': releaseInfo['assets'][0]['browser_download_url'],
        };
      }
      throw Exception('Failed to check for updates');
    } catch (e) {
      throw Exception('Error checking for updates: $e');
    }
  }

  static Future<Map<String, dynamic>> checkResourceUpdates() async {
    try {
      final response = await http.get(Uri.parse(_resourcesManifestUrl));
      if (response.statusCode == 200) {
        final manifest = json.decode(response.body);
        final updates = <String, dynamic>{};

        for (final resource in manifest['resources']) {
          final localVersion = await _getLocalResourceVersion(resource['name']);
          if (localVersion == null || _compareVersions(resource['version'], localVersion) > 0) {
            updates[resource['name']] = {
              'version': resource['version'],
              'url': resource['url'],
              'size': resource['size'],
              'checksum': resource['checksum'],
            };
          }
        }

        return {
          'hasUpdates': updates.isNotEmpty,
          'updates': updates,
        };
      }
      throw Exception('Failed to check for resource updates');
    } catch (e) {
      throw Exception('Error checking for resource updates: $e');
    }
  }

  static Future<void> downloadAndInstallUpdate(String url, void Function(double) onProgress) async {
    try {
      final client = http.Client();
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      final contentLength = response.contentLength ?? 0;
      var received = 0;

      final updateDir = await _getUpdateDirectory();
      final updateFile = File(path.join(updateDir.path, 'update.zip'));
      final output = updateFile.openWrite();

      await for (final chunk in response.stream) {
        output.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }

      await output.close();
      await _installUpdate(updateFile);
    } catch (e) {
      throw InstallationException('Failed to download and install update: $e');
    }
  }

  static Future<void> updateResource(
    String resourceName,
    Map<String, dynamic> resourceInfo,
    void Function(double) onProgress,
  ) async {
    try {
      final client = http.Client();
      final response = await client.send(http.Request('GET', Uri.parse(resourceInfo['url'])));
      final contentLength = response.contentLength ?? 0;
      var received = 0;

      final resourceDir = await _getResourceDirectory(resourceName);
      final resourceFile = File(path.join(resourceDir.path, '$resourceName.zip'));
      final output = resourceFile.openWrite();

      await for (final chunk in response.stream) {
        output.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }

      await output.close();
      
      // Verify checksum
      if (!await _verifyChecksum(resourceFile, resourceInfo['checksum'])) {
        await resourceFile.delete();
        throw InstallationException('Resource checksum verification failed');
      }

      await _installResource(resourceName, resourceFile);
      await _saveResourceVersion(resourceName, resourceInfo['version']);
    } catch (e) {
      throw InstallationException('Failed to update resource: $e');
    }
  }

  static Future<Directory> _getUpdateDirectory() async {
    final cacheDir = await CacheManager.getCacheDirectory();
    final updateDir = Directory(path.join(cacheDir, 'updates'));
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }
    return updateDir;
  }

  static Future<Directory> _getResourceDirectory(String resourceName) async {
    final cacheDir = await CacheManager.getCacheDirectory();
    final resourceDir = Directory(path.join(cacheDir, 'resources', resourceName));
    if (!await resourceDir.exists()) {
      await resourceDir.create(recursive: true);
    }
    return resourceDir;
  }

  static Future<void> _installUpdate(File updateFile) async {
    // Platform-specific update installation
    if (Platform.isWindows) {
      // TODO: Implement Windows update installation
    } else if (Platform.isAndroid) {
      // TODO: Implement Android update installation
    }
  }

  static Future<void> _installResource(String resourceName, File resourceFile) async {
    // Extract and install resource
    // TODO: Implement resource installation
  }

  static Future<String?> _getLocalResourceVersion(String resourceName) async {
    try {
      final versionFile = File(path.join((await _getResourceDirectory(resourceName)).path, 'version'));
      if (await versionFile.exists()) {
        return await versionFile.readAsString();
      }
    } catch (e) {
      print('Error reading resource version: $e');
    }
    return null;
  }

  static Future<void> _saveResourceVersion(String resourceName, String version) async {
    final versionFile = File(path.join((await _getResourceDirectory(resourceName)).path, 'version'));
    await versionFile.writeAsString(version);
  }

  static Future<bool> _verifyChecksum(File file, String expectedChecksum) async {
    // TODO: Implement checksum verification
    return true;
  }

  static int _compareVersions(String v1, String v2) {
    final version1 = v1.split('.').map(int.parse).toList();
    final version2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final diff = version1[i] - version2[i];
      if (diff != 0) return diff;
    }
    return 0;
  }
}
