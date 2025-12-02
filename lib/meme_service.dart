import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:meme_downloader/models/meme.dart';
import 'package:meme_downloader/download_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  ) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        if (Platform.isAndroid || Platform.isIOS) {
          await ImageGallerySaver.saveImage(
            response.bodyBytes,
            name: fileName,
            isReturnImagePathOfIOS: true,
          );
        } else {
          Directory? downloadsDir;
          if (Platform.isWindows || Platform.isMacOS) {
            downloadsDir = await getDownloadsDirectory();
          } else if (Platform.isLinux) {
            downloadsDir = Directory.current;
          }

          if (downloadsDir != null) {
            final memesDir = Directory(path.join(downloadsDir.path, 'memes'));
            if (!await memesDir.exists()) {
              await memesDir.create(recursive: true);
            }
            final file = File(path.join(memesDir.path, fileName));
            await file.writeAsBytes(response.bodyBytes);
          }
        }
        downloadService.incrementTaskProgress(taskName);
      }
      // Add a small delay to avoid rate-limiting
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      // Handle or log the error
      print('Error downloading $url: $e');
    }
  }
}
