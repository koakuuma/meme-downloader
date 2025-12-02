import 'dart:async';
import 'package:meme_downloader/models/download_task.dart';

class DownloadService {
  final _tasks = <String, DownloadTask>{};
  final _controller = StreamController<List<DownloadTask>>.broadcast();
  List<DownloadTask> _lastTasks = [];

  Stream<List<DownloadTask>> get tasks => _controller.stream;
  List<DownloadTask> get lastTasks => _lastTasks;

  void _updateStream() {
    _lastTasks = _tasks.values.toList();
    _controller.add(_lastTasks);
  }

  void startTask(String name, int total) {
    _tasks[name] = DownloadTask(name: name, total: total);
    _updateStream();
  }

  void incrementTaskProgress(String name) {
    if (_tasks.containsKey(name)) {
      final task = _tasks[name]!;
      if (task.completed < task.total) {
        task.completed++;
        _updateStream();
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}
