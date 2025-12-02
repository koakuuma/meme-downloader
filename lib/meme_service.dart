import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:meme_downloader/models/meme.dart';
import 'package:meme_downloader/download_service.dart';

class MemeService {
  Future<List<Meme>> loadMemes() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final memeTxtPaths = manifestMap.keys
        .where((String key) => key.startsWith('assets/meme_txts/'))
        .toList();

    List<Meme> memes = [];
    for (String path in memeTxtPaths) {
      final txtContent = await rootBundle.loadString(path);
      final urls = txtContent
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map(
            (line) => line.startsWith('http')
                ? line
                : 'https://i0.hdslb.com/bfs/' + line,
          )
          .toList();

      if (urls.isNotEmpty) {
        final memeName = path.split('/').last.replaceAll('.txt', '');
        final cover = urls[Random().nextInt(urls.length)];
        memes.add(Meme(name: memeName, cover: cover, urls: urls));
      }
    }
    return memes;
  }

  Future<void> downloadMeme(
    String url,
    String fileName,
    DownloadService downloadService,
    String taskName,
    int completed,
  ) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        downloadService.updateTask(taskName, completed + 1);
      }
    }
  }
}
