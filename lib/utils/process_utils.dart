import 'dart:async';
import 'dart:convert';

class ProcessUtils {
  static StreamTransformer<List<int>, double> progressExtractor() {
    return StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<double> sink) {
        final String output = utf8.decode(data);
        final RegExp progressRegex = RegExp(r'(\d+(?:\.\d+)?)%');
        final match = progressRegex.firstMatch(output);
        if (match != null) {
          final progress = double.parse(match.group(1)!) / 100;
          sink.add(progress);
        }
      },
    );
  }

  static StreamTransformer<List<int>, String> logExtractor() {
    return StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<String> sink) {
        final String output = utf8.decode(data);
        // Split by newlines and filter out empty lines
        final lines = output.split('\n').where((line) => line.trim().isNotEmpty);
        for (var line in lines) {
          sink.add(line.trim());
        }
      },
    );
  }
}
