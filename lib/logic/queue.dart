import '../models/queued_file.dart';

class QueueManager {
  static void addFile(List<QueuedFile> queue, QueuedFile file) {
    if (!queue.any((f) => f.name == file.name)) {
      queue.add(file);
    }
  }

  static void clearQueue(List<QueuedFile> queue) {
    queue.clear();
  }

  static void removeCompleted(List<QueuedFile> queue) {
    queue.removeWhere((f) => f.status == 'Completed' || f.status == 'Failed');
  }

  static void retryFile(List<QueuedFile> queue, int idx) {
    queue[idx] = QueuedFile(
      name: queue[idx].name,
      status: 'Waiting',
      progress: null,
    );
  }
}
