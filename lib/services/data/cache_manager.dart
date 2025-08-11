import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CacheManager {
  static const int _maxCacheSize = 1024 * 1024 * 1024; // 1GB
  static const Duration _maxCacheAge = Duration(days: 7);

  static Future<String> getCacheDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  static Future<void> clearCache() async {
    final cacheDir = Directory(await getCacheDirectory());
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }
  }

  static Future<void> cleanupCache() async {
    final cacheDir = Directory(await getCacheDirectory());
    if (!await cacheDir.exists()) return;

    var totalSize = 0;
    final now = DateTime.now();
    final filesToDelete = <File>[];
    final files = await cacheDir.list(recursive: true).where((entity) => entity is File).cast<File>().toList();

    // Sort files by last accessed time
    files.sort((a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));

    for (final file in files) {
      final stat = await file.stat();
      final age = now.difference(stat.modified);
      final size = stat.size;

      if (age > _maxCacheAge) {
        filesToDelete.add(file);
        continue;
      }

      totalSize += size;
      if (totalSize > _maxCacheSize) {
        filesToDelete.add(file);
      }
    }

    // Delete files that are too old or exceed cache size
    for (final file in filesToDelete) {
      try {
        await file.delete();
      } catch (e) {
        print('Error deleting cached file: $e');
      }
    }
  }

  static Future<File> getCachedFile(String key) async {
    final cacheDir = await getCacheDirectory();
    return File(path.join(cacheDir, key));
  }

  static Future<bool> hasCachedFile(String key) async {
    final file = await getCachedFile(key);
    return file.exists();
  }

  static Future<void> cacheFile(String key, List<int> data) async {
    final file = await getCachedFile(key);
    await file.writeAsBytes(data);
    await cleanupCache();
  }

  static Future<List<int>?> getCachedData(String key) async {
    final file = await getCachedFile(key);
    if (await file.exists()) {
      try {
        final data = await file.readAsBytes();
        // Update last accessed time
        await file.setLastModified(DateTime.now());
        return data;
      } catch (e) {
        print('Error reading cached file: $e');
        return null;
      }
    }
    return null;
  }

  static Future<int> getCacheSize() async {
    final cacheDir = Directory(await getCacheDirectory());
    if (!await cacheDir.exists()) return 0;

    var size = 0;
    await for (final file in cacheDir.list(recursive: true)) {
      if (file is File) {
        size += await file.length();
      }
    }
    return size;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
