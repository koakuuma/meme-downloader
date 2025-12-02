import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MemeService {
  Future<List<String>> loadMemeTxts() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final memeTxtPaths = manifestMap.keys
        .where((String key) => key.startsWith('assets/meme_txts/'))
        .toList();
    return memeTxtPaths;
  }

  Future<void> downloadMeme(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
      }
    }
  }
}
