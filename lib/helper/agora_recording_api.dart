import 'dart:convert';
import 'package:agora_demo/const.dart';
import 'package:http/http.dart' as http;

class AgoraRecordingApi {
  final String customerId = '<!--your customer id goes here-->';
  final String customerSecret = '<!--your customer secret goes here-->';

  String get auth => base64.encode(utf8.encode("$customerId:$customerSecret"));

  Future<String?> acquireResource(
      String channelName,
      String uid,
      ) async {
    try {
      var headers = {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'POST',
          Uri.parse(
              'https://api.agora.io/v1/apps/$appId/cloud_recording/acquire'));
      request.body = json.encode({
        "cname": channelName,
        "uid": uid,
        "clientRequest": {"resourceExpiredHour": 72}
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String resStr = await response.stream.bytesToString();
        if (resStr.isNotEmpty) {
          var resObj = jsonDecode(resStr);
          print('resourceId: ${resObj['resourceId']}');
          return resObj['resourceId'];
        } else {
          return null;
        }
      } else {
        print('Could not acquire resource : ${response.statusCode}');
        print('response body :  ${response.reasonPhrase}');
        print('response headers :  ${response.headers}');
        print('response reason phrase :  ${response.reasonPhrase}');
        return null;
      }
    } catch (e, stackTrace) {
      print("error in acquire : ${e.toString()}");
      print("stacktrace is $stackTrace");
      return null;
    }
  }

  // start recording method call
  Future<Map<String, dynamic>?> startRecording({
    required String channelName,
    required String token,
    required String userId,
    required String resourceID,
    required List<String> fileNamePrefix,
  }) async {
    try {
      var headers = {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json'
      };
      var response = await http.post(
        Uri.parse('https://api.agora'
            '.io/v1/apps/$appId/cloud_recording/resourceid'
            '/$resourceID/mode/mix/start'),
        body: json.encode({
          "cname": channelName,
          "uid": userId,
          "clientRequest": {
            "token": token,
            "recordingConfig": {
              "channelType": 0,
              "streamTypes": 2,
              "audioProfile": 1,
              "videoStreamType": 0,
              "avFileType": ["hls", "mp4"],
              "maxIdleTime": 120,
              "transcodingConfig": {
                "width": 360,
                "height": 640,
                "fps": 30,
                "bitrate": 600,
                "maxResolutionUid": "1",
                "mixedVideoLayout": 1
              }
            },
            "recordingFileConfig": {
              "avFileType": ["hls", "mp4"]
            },
            "storageConfig": {
              "secretKey": '<!--Your app secret-->',
              "vendor": 6,
              "region": 0,
              "bucket": '<!--Your bucket name-->',
              "accessKey": '<!--Your access key-->',
              "fileNamePrefix": fileNamePrefix,
            }
          }
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String resStr = response.body;
        if (resStr.isNotEmpty) {
          var resObj = jsonDecode(resStr);
          print('resourceId: ${resObj['resourceId']}');
          print('sid: ${resObj['sid']}');
          return {
            'sid': resObj['sid'],
            'resourceId': resObj['resourceId'],
          };
        } else {
          return null;
        }
      } else {
        print('Could not start the recording : ${response.statusCode}');
        print('response body :  ${response.reasonPhrase}');
        print('response headers :  ${response.headers}');
        print('response reason phrase :  ${response.reasonPhrase}');
      }
    } catch (e) {
      print("error : $e");
    }
    return null;
  }

  // stop recording method call
  Future stopRecording(
      String mChannelName,
      String resourceID,
      String sid,
      String uId,
      ) async {
    try {
      var headers = {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json'
      };
      var response = await http.post(
        Uri.parse(
            'https://api.agora.io/v1/apps/$appId/cloud_recording/resourceid'
                '/$resourceID/sid/$sid/mode/mix/stop'),
        body: json.encode({
          "cname": mChannelName,
          "uid": uId,
          "clientRequest": {"resourceExpiredHour": 24}
        }),
        headers: headers,
      );
      if (response.statusCode == 200) {
        print("Body: ${response.body}");
        return jsonDecode(response.body);
      } else {
        print('Could not stop resource : ${response.statusCode}');
        print('response body :  ${response.reasonPhrase}');
        print('response headers :  ${response.headers}');
        print('response reason phrase :  ${response.reasonPhrase}');
        print('response :  ${response.body}');
      }
    } catch (e, stackTrace) {
      print("error in acquire : ${e.toString()}");
      print("stacktrace is $stackTrace");
    }
  }

  // Query recording method call
  Future<void> queryRecording({
    required String mChannelName,
    required String resourceID,
    required String sid,
    required String uId,
  }) async {
    try {
      var headers = {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json'
      };
      var response = await http.get(
        Uri.parse(
            'https://api.agora.io/v1/apps/$appId/cloud_recording/resourceid'
                '/$resourceID/sid/$sid/mode/mix/query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print(response.body);
      } else {
        print('Could not query resource : ${response.statusCode}');
        print('response body :  ${response.reasonPhrase}');
        print('response headers :  ${response.headers}');
        print('response reason phrase :  ${response.reasonPhrase}');
        print('response :  ${response.body}');
      }
    } catch (e, stackTrace) {
      print("error in acquire : ${e.toString()}");
      print("stacktrace is $stackTrace");
    }
  }
}