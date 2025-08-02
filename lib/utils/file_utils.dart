import 'dart:io';

class FileUtils {
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String getDirectory(String path) {
    return path.substring(0, path.lastIndexOf(Platform.pathSeparator));
  }

  static String getGeneratedCCPath(String inputPath, String format) {
    final dir = getDirectory(inputPath);
    final base = getFileName(inputPath).replaceAll(RegExp(r'\.[^.]*$'), '');
    return '$dir${Platform.pathSeparator}$base$format';
  }

  static String getTranslatedCCPath(String inputPath, String format, String language) {
    final dir = getDirectory(inputPath);
    final base = getFileName(inputPath).replaceAll(RegExp(r'\.[^.]*$'), '');
    return '$dir${Platform.pathSeparator}${base}_Translated_$language$format';
  }

  static bool isAudio(String fileName) {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.mp3') || ext.endsWith('.wav') || ext.endsWith('.flac') || ext.endsWith('.aac') || ext.endsWith('.ogg');
  }

  static bool isVideo(String fileName) {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.mkv') || ext.endsWith('.avi') || ext.endsWith('.mov') || ext.endsWith('.webm');
  }

  static bool isSubtitle(String fileName) {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.srt') || ext.endsWith('.vtt') || ext.endsWith('.ass') || ext.endsWith('.txt');
  }
}
