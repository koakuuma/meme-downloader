import 'dart:async';
import 'package:meme_downloader/models/download_task.dart';

class DownloadService {
  final _tasks = <String, DownloadTask>{};
  final _controller = StreamController<List<DownloadTask>>.broadcast();

  Stream<List<DownloadTask>> get tasks => _controller.stream;

  void startTask(String name, int total) {
    _tasks[name] = DownloadTask(name: name, total: total);
    _controller.add(_tasks.values.toList());
  }

  void updateTask(String name, int completed) {
    if (_tasks.containsKey(name)) {
      _tasks[name]!.completed = completed;
      _controller.add(_tasks.values.toList());
    }
  }

  void dispose() {
    _controller.close();
  }
}
