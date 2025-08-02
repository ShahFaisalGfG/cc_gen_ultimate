import 'package:flutter/foundation.dart';
import '../logic/logs.dart';

class LogsState extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void addLog(String message, {LogLevel level = LogLevel.info}) {
    _logs.add(LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    ));
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
