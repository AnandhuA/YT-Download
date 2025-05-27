import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class YouTubeDownloader extends StatefulWidget {
  const YouTubeDownloader({super.key});

  @override
  State<YouTubeDownloader> createState() => _YouTubeDownloaderState();
}

class _YouTubeDownloaderState extends State<YouTubeDownloader> {
  TextEditingController urlController = TextEditingController();
  String? cookiesPath;
  String output = "";
  double progress = 0.0;
  bool _buttonClick = false;
  bool downloadComplete = false;

  Future<void> pickCookiesFile() async {
    // downloadComplete = true;
    // setState(() {});
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        cookiesPath = result.files.single.path!;
      });
    }
  }

  Future<void> downloadVideo() async {
    _buttonClick = true;
    final url = urlController.text.trim();
    if (url.isEmpty || cookiesPath == null) return;

    setState(() {
      output = "";
      progress = 0.0;
    });

    final ytDlpPath = '${Directory.current.path}\\windows\\yt-dlp_x86.exe';

    final downloadDir =
        '${Platform.environment['USERPROFILE']}\\Downloads\\Videos';

    final process = await Process.start(ytDlpPath, [
      '-f',
      'bestvideo+bestaudio',
      '--merge-output-format',
      'mp4',
      '--cookies',
      cookiesPath!,
      '-o',
      '$downloadDir/%(title)s.%(ext)s',
      url,
    ], runInShell: true);

    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      setState(() {
        output += data;

        final match = RegExp(r'\[download\]\s+(\d+\.\d+)%').firstMatch(data);
        if (match != null) {
          progress = double.tryParse(match.group(1)!)! / 100;
        }
      });
    });

    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      log(data);
      setState(() {
        output += '\n[Error] $data';
      });
    });

    final exitCode = await process.exitCode;
    setState(() {
      output += '\nDownload finished with exit code $exitCode';
      progress = 1.0;
      downloadComplete = true;
    });
    try {
      final file = File(cookiesPath!);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          output += '\nCookies file deleted successfully.';
          cookiesPath = null;
        });
      }
    } catch (e) {
      setState(() {
        output += '\n[Warning] Failed to delete cookies file: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('YouTube Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 10,
          children: [
            if (!_buttonClick)
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'YouTube URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (!_buttonClick)
              ElevatedButton(
                onPressed: pickCookiesFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      cookiesPath != null ? Colors.green : Colors.red,
                ),
                child: Text(
                  cookiesPath != null
                      ? 'Cookies Selected'
                      : 'Pick Cookies File',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            downloadComplete
                ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      urlController.clear();
                      cookiesPath = null;
                      output = "";
                      progress = 0.0;
                      _buttonClick = false;
                      downloadComplete = false;
                    });
                  },
                  child: Text("Clear", style: TextStyle(color: Colors.white)),
                )
                : _buttonClick
                ? SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Lottie.asset("assets/downloading.json"),
                )
                : ElevatedButton(
                  onPressed: downloadVideo,

                  child: const Text(
                    'Download Max Quality',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            const SizedBox(height: 20),
            if (_buttonClick)
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: Colors.cyan,
              ),
            const SizedBox(height: 10),
            downloadComplete
                ? SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Lottie.asset("assets/downloaded.json", repeat: false),
                )
                : Expanded(
                  child: SingleChildScrollView(
                    child: Text(output, style: const TextStyle(fontSize: 12)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
