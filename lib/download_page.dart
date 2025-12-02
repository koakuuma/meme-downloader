import 'package:flutter/material.dart';
import 'package:meme_downloader/download_service.dart';
import 'package:meme_downloader/models/download_task.dart';

class DownloadPage extends StatelessWidget {
  final DownloadService downloadService;

  const DownloadPage({super.key, required this.downloadService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Progress')),
      body: StreamBuilder<List<DownloadTask>>(
        stream: downloadService.tasks,
        initialData: downloadService.lastTasks,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No download tasks.'));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: task.progress),
                    Text(
                      '${(task.progress * 100).toStringAsFixed(1)}% (${task.completed}/${task.total})',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
