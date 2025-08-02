import '../models/queued_file.dart';

class BatchActions {
  static void removeCompleted(List<QueuedFile> queue) {
    queue.removeWhere((f) => f.status == 'Completed' || f.status == 'Failed');
  }

  static void retryFailed(List<QueuedFile> queue) {
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].status == 'Failed') {
        queue[i] = QueuedFile(
          name: queue[i].name,
          status: 'Waiting',
          progress: null,
        );
      }
    }
  }

  static void clearQueue(List<QueuedFile> queue) {
    queue.clear();
  }
}
