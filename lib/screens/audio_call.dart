import 'dart:math';

import 'package:agora_demo/helper/agora_helper.dart';
import 'package:agora_demo/helper/app_enums.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class AudioCall extends StatefulWidget {
  const AudioCall({
    Key? key,
    required this.title,
    required this.isHost,
  }) : super(key: key);

  final String title;
  final bool isHost;

  @override
  State<AudioCall> createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {
  String channelName = "<!--Insert channel name here-->";
  String token = "<!--Insert authentication token here-->";
  late int localUid;

  late RtcEngine agoraEngine;
  AgoraHelper agoraHelper = AgoraHelper();
  bool isJoined = false;

  List<Map<String, dynamic>> remoteUserIdsList = [];

  @override
  void initState() {
    super.initState();
    agoraHelper.channelName = channelName;
    agoraHelper.token = token;
    setupEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: !isJoined
          ? const Center(
              child: Text('Please wait'),
            )
          : ListView.builder(
              itemCount: remoteUserIdsList.length,
              itemBuilder: (listContext, index) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50.0,
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                    color: Colors.black87,
                    width: 1.0,
                  ))),
                  child: Row(
                    children: [
                      Text(
                        "${remoteUserIdsList[index]['id']}",
                      ),
                      if (remoteUserIdsList[index]['speaking']) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      ]
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  Future<void> dispose() async {
    await agoraHelper.leave(agoraEngine);
    super.dispose();
  }

  /// Setup RTC engine
  Future<void> setupEngine() async {
    // initialise rtc engine
    agoraEngine = await agoraHelper.onCreateEngine();

    // enable video
    agoraHelper.enableAudioVideo(
      agoraEngine,
      ChannelType.audio,
    );

    // event callback
    rtcEventCallbacks();

    // enable preview
    agoraHelper.startCameraPreview(agoraEngine);

    int min = 1000; //min and max values act as your 4 digit range
    int max = 9999;
    localUid = min + Random().nextInt(max - min);

    // join channel
    agoraHelper.joinChannel(
      agoraEngine,
      widget.isHost ? UserType.host : UserType.audience,
      ChannelMode.callMode,
      localUid,
    );
  }

  /// RTC event call backs
  void rtcEventCallbacks() {
    agoraEngine.registerEventHandler(RtcEngineEventHandler(
      // When local user joins a channel successfully
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print('User agora id: ${connection.localUid}');
        if (!remoteUserIdsList.any((element) => element['id'] == localUid)) {
          remoteUserIdsList.add({'id': localUid, 'speaking': false});
        }
        setState(() {
          isJoined = true;
        });
      },

      // When a user joins as broadcaster
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print('Remote user: $remoteUid');
        setState(() {
          remoteUserIdsList.add({'id': remoteUid, 'speaking': false});
        });
      },

      // When a remote user leaves the channel/call
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print('User $remoteUid left the channel');
      },

      // When local user leaves the channel
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        // Do your stuff here
      },

      // When a user mute/un-mute audio
      onRemoteAudioStateChanged: (connection, uid, state, reason, elapsed) {
        print('Audio state reason: $reason');
      },

      // When a user mute/un-mute video
      onRemoteVideoStateChanged: (connection, uid, state, reason, elapsed) {
        print('Video state reason: $reason');
      },

      // Up-to 3 active speaker volume info will get
      onAudioVolumeIndication: (
        RtcConnection connection,
        List<AudioVolumeInfo> speakers,
        int speakerNumber,
        int totalVolume,
      ) {
        for (AudioVolumeInfo audioVolumeInfo in speakers) {
          // Here for local user uid will be 0
          int index = remoteUserIdsList.indexWhere((element) =>
              element['id'] ==
              (audioVolumeInfo.uid == 0 ? localUid : audioVolumeInfo.uid));
          setState(() {
            remoteUserIdsList[index]['speaking'] =
                (audioVolumeInfo.volume ?? 0) > 0;
          });
        }
      },
    ));
  }
}
