import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meme_downloader/download_page.dart';
import 'package:meme_downloader/download_service.dart';
import 'package:meme_downloader/meme_service.dart';
import 'package:meme_downloader/models/meme.dart';

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
  final DownloadService _downloadService = DownloadService();
  late Future<List<Meme>> _memesFuture;
  bool _isSelectionMode = false;
  Set<String> _selectedMemes = {};
  List<Meme> _memes = [];

  @override
  void initState() {
    super.initState();
    _memesFuture = _memeService.loadMemes();
    _memesFuture.then((value) => setState(() => _memes = value));
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMemes.clear();
      }
    });
  }

  void _toggleMemeSelection(String memeName) {
    setState(() {
      if (_selectedMemes.contains(memeName)) {
        _selectedMemes.remove(memeName);
      } else {
        _selectedMemes.add(memeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedMemes.length} selected'
              : 'Meme Downloader',
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  if (_selectedMemes.length == _memes.length) {
                    _selectedMemes.clear();
                  } else {
                    _selectedMemes = _memes.map((m) => m.name).toSet();
                  }
                });
              },
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                for (String memeName in _selectedMemes) {
                  final meme = _memes.firstWhere((m) => m.name == memeName);
                  _downloadService.startTask(meme.name, meme.urls.length);
                  _memeService.downloadMemes(meme, _downloadService);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Started downloading ${_selectedMemes.length} memes...',
                    ),
                  ),
                );
                _toggleSelectionMode();
              },
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DownloadPage(downloadService: _downloadService),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Meme>>(
        future: _memesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No memes found.'));
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _memes.length,
              itemBuilder: (context, index) {
                final meme = _memes[index];
                final isSelected = _selectedMemes.contains(meme.name);
                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleMemeSelection(meme.name);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => MemePreviewDialog(
                          meme: meme,
                          memeService: _memeService,
                          downloadService: _downloadService,
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _toggleSelectionMode();
                      _toggleMemeSelection(meme.name);
                    }
                  },
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(meme.name, textAlign: TextAlign.center),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          meme.cover,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                        if (_isSelectionMode)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class MemePreviewDialog extends StatefulWidget {
  final Meme meme;
  final MemeService memeService;
  final DownloadService downloadService;

  const MemePreviewDialog({
    super.key,
    required this.meme,
    required this.memeService,
    required this.downloadService,
  });

  @override
  State<MemePreviewDialog> createState() => _MemePreviewDialogState();
}

class _MemePreviewDialogState extends State<MemePreviewDialog> {
  late String _currentCover;

  @override
  void initState() {
    super.initState();
    _currentCover = widget.meme.cover;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: GestureDetector(
        onDoubleTap: () {
          setState(() {
            _currentCover =
                widget.meme.urls[Random().nextInt(widget.meme.urls.length)];
          });
        },
        child: Container(
          height: 300, // Fixed height for the image container
          child: Image.network(_currentCover, fit: BoxFit.contain),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentCover = widget
                      .meme
                      .urls[Random().nextInt(widget.meme.urls.length)];
                });
              },
              child: const Text('换一张'),
            ),
            TextButton(
              onPressed: () {
                final meme = widget.meme;
                widget.downloadService.startTask(meme.name, meme.urls.length);
                widget.memeService.downloadMemes(meme, widget.downloadService);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Started downloading ${meme.name}...'),
                  ),
                );
              },
              child: const Text('下载此表情包'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ],
    );
  }
}
