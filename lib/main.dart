import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meme_downloader/meme_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Downloader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MemeService _memeService = MemeService();
  late Future<List<String>> _memeTxtsFuture;

  @override
  void initState() {
    super.initState();
    _memeTxtsFuture = _memeService.loadMemeTxts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meme Downloader')),
      body: FutureBuilder<List<String>>(
        future: _memeTxtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No memes found.'));
          } else {
            final memeTxts = snapshot.data!;
            return ListView.builder(
              itemCount: memeTxts.length,
              itemBuilder: (context, index) {
                final memeTxt = memeTxts[index];
                final memeName = memeTxt.split('/').last.replaceAll('.txt', '');
                return ListTile(
                  title: Text(memeName),
                  onTap: () async {
                    final txtContent = await rootBundle.loadString(memeTxt);
                    final urls = txtContent
                        .split('\n')
                        .map((line) => line.trim())
                        .where((line) => line.isNotEmpty)
                        .toList();
                    if (urls.isNotEmpty) {
                      final rawUrl = urls[Random().nextInt(urls.length)];
                      final randomUrl = rawUrl.startsWith('http')
                          ? rawUrl
                          : 'https://i0.hdslb.com/bfs/' + rawUrl;
                      final fileName =
                          '${memeName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      await _memeService.downloadMeme(randomUrl, fileName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading $memeName...')),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
