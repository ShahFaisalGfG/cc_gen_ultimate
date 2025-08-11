import 'dart:async';
import 'package:flutter/foundation.dart';

enum TaskStatus {
  queued,
  running,
  completed,
  failed,
  cancelled
}

class Task {
  final String id;
  final String name;
  final Future<void> Function() execute;
  final void Function(double)? onProgress;
  final void Function(String)? onStatus;
  TaskStatus status;
  double progress;
  String? error;

  Task({
    required this.id,
    required this.name,
    required this.execute,
    this.onProgress,
    this.onStatus,
    this.status = TaskStatus.queued,
    this.progress = 0.0,
    this.error,
  });
}

class BackgroundTaskManager extends ChangeNotifier {
  static final BackgroundTaskManager _instance = BackgroundTaskManager._internal();
  factory BackgroundTaskManager() => _instance;
  BackgroundTaskManager._internal();

  final Map<String, Task> _tasks = {};
  final List<Task> _queue = [];
  bool _isProcessing = false;
  int _maxConcurrentTasks = 1;

  List<Task> get tasks => _tasks.values.toList();
  List<Task> get queue => _queue;
  bool get isProcessing => _isProcessing;

  void setMaxConcurrentTasks(int max) {
    _maxConcurrentTasks = max;
    _processQueue();
  }

  Future<void> addTask(Task task) async {
    _tasks[task.id] = task;
    _queue.add(task);
    notifyListeners();
    await _processQueue();
  }

  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      if (task.status == TaskStatus.queued) {
        _queue.remove(task);
      }
      task.status = TaskStatus.cancelled;
      _tasks.remove(taskId);
      notifyListeners();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final activeTasks = _tasks.values.where((t) => t.status == TaskStatus.running).length;
      if (activeTasks >= _maxConcurrentTasks) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final task = _queue.removeAt(0);
      task.status = TaskStatus.running;
      notifyListeners();

      try {
        await task.execute();
        task.status = TaskStatus.completed;
        task.progress = 1.0;
      } catch (e) {
        task.status = TaskStatus.failed;
        task.error = e.toString();
      }

      notifyListeners();
    }

    _isProcessing = false;
    notifyListeners();
  }

  void updateTaskProgress(String taskId, double progress) {
    final task = _tasks[taskId];
    if (task != null) {
      task.progress = progress;
      task.onProgress?.call(progress);
      notifyListeners();
    }
  }

  void updateTaskStatus(String taskId, String status) {
    final task = _tasks[taskId];
    if (task != null) {
      task.onStatus?.call(status);
      notifyListeners();
    }
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((_, task) => 
      task.status == TaskStatus.completed || 
      task.status == TaskStatus.cancelled
    );
    notifyListeners();
  }

  void retryFailedTasks() {
    final failedTasks = _tasks.values.where((t) => t.status == TaskStatus.failed).toList();
    for (final task in failedTasks) {
      task.status = TaskStatus.queued;
      task.error = null;
      task.progress = 0.0;
      _queue.add(task);
    }
    _processQueue();
  }
}
