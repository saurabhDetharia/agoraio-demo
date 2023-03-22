import 'dart:math';

import 'package:agora_demo/const.dart';
import 'package:agora_demo/helper/agora_recording_api.dart';
import 'package:agora_demo/helper/app_enums.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

abstract class AgoraConnector {
  Future<RtcEngine> onCreateEngine();

  Future<void> enableAudioVideo(
    RtcEngine agoraEngine,
    ChannelType streamType,
  );

  Future<void> startCameraPreview(
    RtcEngine agoraEngine,
  );

  Future<void> joinChannel(
    RtcEngine agoraEngine,
    UserType userType,
    ChannelMode channelMode,
    int uid,
  );

  Future<void> leave(
    RtcEngine agoraEngine,
  );

  Future<void> updateUserRole(
    RtcEngine agoraEngine,
    UserType userType,
  );

  Future<void> configureSpatialAudioEngine(
    RtcEngine agoraEngine,
    LocalSpatialAudioEngine localSpatial,
  );

  void updateRemotePosition(
    double distance,
    LocalSpatialAudioEngine localSpatial,
    int remoteUid,
  );

  Future<Map<String, dynamic>?> startRecording();

  Future<void> stopRecording(
    String channel,
    String resourceID,
    String sid,
    String recordingId,
  );
}

class AgoraHelper extends AgoraConnector {
  late RtcEngine rtcEngine;
  late String channelName;
  late String token;

  /// To create RTC engine instance
  @override
  Future<RtcEngine> onCreateEngine() async {
    RtcEngine agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(
      const RtcEngineContext(
        appId: appId, // defined in const.dart
      ),
    );
    return agoraEngine;
  }

  /// To enable audio/video
  @override
  Future<void> enableAudioVideo(
    RtcEngine agoraEngine,
    ChannelType streamType,
  ) async {
    if (streamType == ChannelType.audio) {
      agoraEngine.enableAudio();
      // Optional: if you want to get the volume indications
      agoraEngine.enableAudioVolumeIndication(
        interval: 300,
        smooth: 3,
        reportVad: true,
      );
    } else {
      // Set the device configuration
      await agoraEngine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: 1280,
            height: 720,
          ),
          frameRate: 24,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      agoraEngine.enableVideo(); // audio will be automatically enabled.
    }
  }

  /// To start the camera preview
  @override
  Future<void> startCameraPreview(RtcEngine agoraEngine) async {
    await agoraEngine.startPreview(
      // To define which source should show in the stream
      sourceType: VideoSourceType.videoSourceCameraPrimary,
    );
  }

  /// To join the stream or call
  @override
  joinChannel(
    RtcEngine agoraEngine,
    UserType userType,
    ChannelMode channelMode,
    int uid,
  ) async {
    late ClientRoleType clientRoleType;
    late ChannelProfileType channelProfileType;

    // If the user is host or co-host, assign broadcaster role.
    if (userType == UserType.host || userType == UserType.coHost) {
      clientRoleType = ClientRoleType.clientRoleBroadcaster;
    } else if (userType == UserType.audience) {
      clientRoleType = ClientRoleType.clientRoleAudience;
    }

    // Set the profile based on video call or streaming
    if (channelMode == ChannelMode.callMode) {
      channelProfileType = ChannelProfileType.channelProfileCommunication;
    } else if (channelMode == ChannelMode.streamMode) {
      channelProfileType = ChannelProfileType.channelProfileLiveBroadcasting;
    }

    ChannelMediaOptions options = ChannelMediaOptions(
      clientRoleType: clientRoleType,
      channelProfile: channelProfileType,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  /// To leave the channel
  @override
  Future<void> leave(RtcEngine agoraEngine) async {
    await agoraEngine.leaveChannel();
    agoraEngine.release();
  }

  /// Acquire the token and start recording
  @override
  Future<Map<String, dynamic>?> startRecording() async {
    int min = 1000; //min and max values act as your 4 digit range
    int max = 9999;

    // Generate new uid for recording
    var recordingUid = min + Random().nextInt(max - min);

    // Get resource id
    String? resourceId = await AgoraRecordingApi().acquireResource(
      channelName,
      recordingUid.toString(),
    );

    // Start recording
    Map<String, dynamic>? recordingInfo =
        await AgoraRecordingApi().startRecording(
      channelName: channelName,
      token: '<!--Generate token based on new uid-->',
      userId: recordingUid.toString(),
      resourceID: resourceId!,
      fileNamePrefix: [
        'test_demo',
      ],
    );

    // Get sid
    if (recordingInfo != null) {
      var sid = recordingInfo['sid'];
      return {
        'sid': sid,
        'resourceId': resourceId,
        'recordingUid': recordingUid,
      };
    }
    return null;
  }

  /// Stop recording
  @override
  Future<void> stopRecording(
    String channel,
    String resourceID,
    String sid,
    String recordingId,
  ) async {
    await AgoraRecordingApi()
        .stopRecording(channel, resourceID, sid, recordingId);
  }

  /// Update user role
  @override
  Future<void> updateUserRole(
    RtcEngine agoraEngine,
    UserType userType,
  ) async {
    await agoraEngine.setClientRole(
      role: userType == UserType.audience
          ? ClientRoleType.clientRoleAudience
          : ClientRoleType.clientRoleBroadcaster,
    );
  }

  /// Setup spatial effect
  @override
  Future<void> configureSpatialAudioEngine(
    RtcEngine agoraEngine,
    LocalSpatialAudioEngine localSpatial,
  ) async {
    // Enable spatial audio
    await agoraEngine.enableSpatialAudio(true);

    // Get the spatial audio engine
    localSpatial = agoraEngine.getLocalSpatialAudioEngine();

    // Initialize the spatial audio engine
    localSpatial.initialize();

    // Set the audio reception range of the local user in meters
    localSpatial.setAudioRecvRange(50);

    // Set the length of unit distance in meters
    localSpatial.setDistanceUnit(1);

    // Define the position of the local user
    var pos = [0.0, 0.0, 0.0];
    var axisForward = [1.0, 0.0, 0.0];
    var axisRight = [0.0, 1.0, 0.0];
    var axisUp = [0.0, 0.0, 1.0];

    // Set the position of the local user
    localSpatial.updateSelfPosition(
        position: pos, // The coordinates in the world coordinate system.
        axisForward: axisForward, // The unit vector of the x axis
        axisRight: axisRight, // The unit vector of the y axis
        axisUp: axisUp // The unit vector of the z axis
        );
  }

  /// To apply the effect on a remote user
  @override
  void updateRemotePosition(
    double distance,
    LocalSpatialAudioEngine localSpatial,
    int remoteUid,
  ) {
    // Define the remote user's spatial position
    RemoteVoicePositionInfo positionInfo = RemoteVoicePositionInfo(
      position: [distance, 0.0, 0.0],
      forward: [distance, 0.0, 0.0],
    );

    // Update the spatial position of a remote user
    localSpatial.updateRemotePosition(uid: remoteUid, posInfo: positionInfo);
  }
}
