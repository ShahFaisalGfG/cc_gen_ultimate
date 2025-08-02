import 'dart:io';

Future<void> runWhisperCLI({
  required String filePath,
  required String model,
  required String language,
  required String format,
  required void Function(String) onLog,
  required void Function(double) onProgress,
  required void Function(String) onStatus,
}) async {
  final args = [
    filePath,
    '--model', model,
    '--language', language,
    '--output_format', format.replaceAll('.', ''),
  ];
  onStatus('Processing');
  try {
    final process = await Process.start('cmd.exe', ['/c', 'faster-whisper ${args.join(' ')}'], mode: ProcessStartMode.normal);
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      onLog(data);
      final match = RegExp(r'(\d{1,3})%').firstMatch(data);
      if (match != null) {
        onProgress(int.parse(match.group(1)!) / 100.0);
      }
    });
    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      onLog('[stderr] $data');
    });
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      onStatus('Completed');
    } else {
      onStatus('Failed');
    }
  } catch (e) {
    onLog('Error: $e');
    onStatus('Failed');
  }
}
