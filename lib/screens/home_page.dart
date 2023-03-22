import 'package:agora_demo/app_utils.dart';
import 'package:agora_demo/screens/audio_call.dart';
import 'package:agora_demo/screens/video_call.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isHost = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video call button
            ElevatedButton(
              onPressed: () async {
                [Permission.microphone, Permission.camera].request().then((value) {
                  navigateTo(
                    context,
                    VideoCall(
                      title: "Video calling",
                      isHost: isHost,
                    ),
                  );
                });
              },
              child: const Text("Video call"),
            ),
            // Audio call button
            ElevatedButton(
              onPressed: () async {
                [Permission.microphone].request().then((value) {
                  navigateTo(
                    context,
                    AudioCall(
                      title: "Audio calling",
                      isHost: isHost,
                    ),
                  );
                });
              },
              child: const Text("Audio call"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isHost = !isHost;
          });
        },
        tooltip: isHost ? 'Host' : 'Audience',
        child: Text(
            isHost ? 'Host' : 'Aud'
        ),
      ),
    );
  }
}
