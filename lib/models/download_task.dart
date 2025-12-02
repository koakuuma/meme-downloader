class DownloadTask {
  final String name;
  final int total;
  int completed;
  double get progress => total > 0 ? completed / total : 0;

  DownloadTask({required this.name, required this.total, this.completed = 0});
}
