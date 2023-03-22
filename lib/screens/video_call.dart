import 'dart:math';

import 'package:agora_demo/helper/agora_helper.dart';
import 'package:agora_demo/helper/app_enums.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({
    Key? key,
    required this.title,
    required this.isHost,
  }) : super(key: key);

  final String title;
  final bool isHost;

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  String channelName = "<!--Insert channel name here-->";
  String token = "<!--Insert authentication token here-->";
  late int localUid;

  late RtcEngine agoraEngine;
  AgoraHelper agoraHelper = AgoraHelper();
  bool isJoined = false;
  bool isCoHost = false;
  bool isRecording = false;

  List<int> remoteUserIdsList = [];

  String sid = '';
  String resourceId = '';
  String recordingUid = '';

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
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: agoraEngine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                    for (int uId in remoteUserIdsList) ...[
                      Expanded(
                        child: AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: agoraEngine,
                            canvas: VideoCanvas(uid: uId),
                            connection: RtcConnection(
                              channelId: channelName,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Wrap(
                    spacing: 5.0,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() async {
                            isRecording = !isRecording;
                            if (isRecording) {
                              await agoraHelper.startRecording().then((value) {
                                if (value == null) {
                                  print('Recording not started');
                                } else {
                                  sid = value['sid'];
                                  resourceId = value['resourceId'];
                                  recordingUid = value['recordingUid'];
                                }
                              });
                            } else {
                              await agoraHelper.stopRecording(
                                channelName,
                                resourceId,
                                sid,
                                recordingUid,
                              );
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: Colors.indigo,
                          ),
                          child: Text(
                            isRecording ? 'Stop Recording' : 'Start Recording',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      !isJoined || (isJoined && widget.isHost)
                          ? const SizedBox()
                          : GestureDetector(
                              onTap: () {
                                setState(() {
                                  isCoHost = !isCoHost;
                                  agoraHelper.updateUserRole(
                                    agoraEngine,
                                    isCoHost ? UserType.coHost : UserType.audience,
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  color: Colors.indigo,
                                ),
                                child: Text(
                                  isCoHost ? 'Leave stage' : 'Become co-host',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    agoraHelper.leave(agoraEngine);
    super.dispose();
  }

  /// Setup RTC engine
  Future<void> setupEngine() async {
    // initialise rtc engine
    agoraEngine = await agoraHelper.onCreateEngine();

    // enable video
    agoraHelper.enableAudioVideo(
      agoraEngine,
      ChannelType.video,
    );

    // event callback
    rtcEventCallbacks();

    // enable preview
    agoraHelper.startCameraPreview(agoraEngine);

    int min = 1000; //min and max values act as your 4 digit range
    int max = 9999;
    var agoraUID = min + Random().nextInt(max - min);

    // join channel
    agoraHelper.joinChannel(
      agoraEngine,
      widget.isHost ? UserType.host : UserType.audience,
      ChannelMode.callMode,
      agoraUID,
    );
  }

  /// RTC event call backs
  void rtcEventCallbacks() {
    agoraEngine.registerEventHandler(RtcEngineEventHandler(
      // When local user joins a channel successfully
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print('User agora id: ${connection.localUid}');
        setState(() {
          isJoined = true;
        });
      },

      // When a user joins as broadcaster
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print('Remote user: $remoteUid');
        remoteUserIdsList.add(remoteUid);
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
          print(
              'Audio volume: ${audioVolumeInfo.uid} :: ${audioVolumeInfo.volume}');
        }
      },
    ));
  }
}
