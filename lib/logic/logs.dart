enum LogLevel {
  info,
  warning,
  error,
  success,
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  const LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  factory LogEntry.info(String message) {
    return LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: LogLevel.info,
    );
  }

  factory LogEntry.warning(String message) {
    return LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: LogLevel.warning,
    );
  }

  factory LogEntry.error(String message) {
    return LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: LogLevel.error,
    );
  }

  factory LogEntry.success(String message) {
    return LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: LogLevel.success,
    );
  }
}

class LogsManager {
  final List<LogEntry> logs = [];
  bool showLogs = false;

  void add(String message, {LogLevel level = LogLevel.info}) {
    logs.add(LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    ));
    showLogs = true;
  }

  void clear() {
    logs.clear();
    showLogs = false;
  }

  List<LogEntry> getLogs() {
    return List.unmodifiable(logs);
  }
}
