// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:agora_rtc_engine/rtc_engine.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
// import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

// void main() {
//   runApp(MyApp());
// }

// /// Define App ID and Token
// const APP_ID = '84e3e86b0e214a1a91323104422194ee';
// const Token =
//     '00684e3e86b0e214a1a91323104422194eeIAAH6hMBnH3xsh+kjYcv9GroYjQCXIvAFfCNHVECXcauFjazwzsAAAAAEAAh21UYE/jQYgEAAQAS+NBi';

// // App class
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// // App state class
// class _MyAppState extends State<MyApp> {
//   bool _joined = false;
//   int? _remoteUid = 0;
//   bool _switch = false;
//   String _channelId = "channelA";

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//   }

//   // Init the app
//   Future<void> initPlatformState() async {
//     // Get microphone permission
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       await [Permission.microphone, Permission.camera].request();
//     }
//     await [Permission.microphone, Permission.camera].request();

//     // Create RTC client instance
//     RtcEngineContext context = RtcEngineContext(APP_ID);
//     var engine = await RtcEngine.createWithContext(context);
//     // Define event handling logic
//     engine.setEventHandler(RtcEngineEventHandler(
//         joinChannelSuccess: (String channel, int uid, int elapsed) {
//       print('local user ${uid} joined - ${channel}');
//       setState(() {
//         _joined = true;
//       });
//     }, userJoined: (int uid, int elapsed) {
//       print('remote user ${uid} joined');
//       setState(() {
//         _remoteUid = uid;
//       });
//     }, userOffline: (int uid, UserOfflineReason reason) {
//       print('userOffline ${uid}');
//       setState(() {
//         _remoteUid = null;
//       });
//     }));
//     // Enable video
//     await engine.enableVideo();
//     // Join channel with channel name as 123
//     await engine.joinChannel(Token, _channelId, null, 111);
//   }

//   // Build chat UI
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Agora Audio Call'),
//         ),
//         body: Stack(children: [
//           Center(
//             child: _renderRemoteVideo(),
//           ),
//           Align(
//             alignment: Alignment.topLeft,
//             child: Container(
//               width: 100,
//               height: 100,
//               child: Center(child: _renderLocalPreview()),
//             ),
//           )
//         ]),
//       ),
//     );
//   }

//   Widget? _renderRemoteVideo() {
//     return RtcLocalView.SurfaceView();
//   }

//   Widget? _renderLocalPreview() {
//     if (_remoteUid != null && _remoteUid != 0) {
//       return RtcRemoteView.SurfaceView(
//         uid: _remoteUid!,
//         channelId: _channelId,
//       );
//     } else {
//       print('리모트UID: ${_remoteUid}');
//       return Text(
//         'Please wait remote user join',
//         textAlign: TextAlign.center,
//       );
//     }
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// 참고 링크
// https://docs.agora.io/en/Voice/API%20Reference/flutter/v5.1.0/API/class_irtcengine.html#ariaid-title10
// https://github.com/AgoraIO/Agora-Flutter-SDK/tree/master/example/lib/examples/advanced
// https://www.youtube.com/watch?v=zVqs1EIpVxs
// https://docs.agora.io/en/Video/API%20Reference/flutter/v4.0.7/agora_rtc_engine/RtcEngine/startAudioRecordingWithConfig.html
// https://www.agora.io/en/pricing/

void main() => runApp(MyApp());

/// Define App ID and Token
const APP_ID = '64422c4e67ec45faa665ec863feda1ec';
const TOKEN =
    '0065ae8a116f36d4a38ade8b126b5cd6cf3IACR5Fn9A26PNAtdO0MEwSwUsVMtwOCxeVovcBPvRUzingx+f9gAAAAAEAAh21UYWgTRYgEAAQBaBNFi';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

// App state class
class _MyAppState extends State<MyApp> {
  // Build chat UI
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Agora Audio quickstart', home: IndexPage());
  }
}

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRole? _role = ClientRole.Broadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Agora Audio quickstart'),
        ),
        body: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: _channelController,
                  decoration: InputDecoration(
                      errorText:
                          _validateError ? 'Channel name is mandatory' : null,
                      border: const UnderlineInputBorder(
                          borderSide: BorderSide(width: 1)),
                      hintText: 'Channel Name'),
                ),
                RadioListTile(
                    value: ClientRole.Broadcaster,
                    title: Text('Broadcast'),
                    groupValue: _role,
                    onChanged: (ClientRole? value) {
                      setState(() {
                        _role = value;
                      });
                    }),
                RadioListTile(
                    value: ClientRole.Audience,
                    title: Text('Audience'),
                    groupValue: _role,
                    onChanged: (ClientRole? value) {
                      setState(() {
                        _role = value;
                      });
                    }),
                ElevatedButton(onPressed: onJoin, child: Text('Join'))
              ]),
        ));
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                    channelName: _channelController.text,
                    role: _role,
                  )));
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}

class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRole? role;
  const CallPage({Key? key, this.channelName, this.role}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  late RtcEngine _engine;
  String p = '';

  @override
  void initState() {
    initialize();
    super.initState();

    init();
  }

  init() async {
    ByteData data = await rootBundle.load("assets/simbols.mp3");
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    p = path.join(appDocDir.path, 'simbols.mp3');
    // final file = File(temp);
    // if (!(await file.exists())) {
    //   await file.create();
    //   await file.writeAsBytes(bytes);
    // }
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add('App Id is missing!');
      });
      return;
    }

    _engine = await RtcEngine.create(APP_ID);

    // 오디오 들리도록 설정
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.Communication);
    // await _engine.setClientRole(widget.role!);

    _addAgoraEventHandlers();
    // VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions = VideoDimensions(width: 1920, height: 1080);

    // 채널 조인하는 함수
    // token, channelName 동적으로 설정되도록 하기
    await _engine.joinChannel(TOKEN, widget.channelName!, null, 0);

    // 아래 두 줄 쓰면 목소리는 죽이고, 북소리만 키워줌
    await _engine.adjustRecordingSignalVolume(0);
    await _engine.adjustAudioMixingVolume(50);
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'Error: $code';
          _infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = "Join Channel: $channel, uid: $uid";
          _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('Leave Channel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'User Joined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, elapsed) {
        final info = 'User Offline: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'First Remote Video: $uid $width x $height';
          _infoStrings.add(info);
        });
      },
      audioMixingFinished: () {
        print('audioMixingFinished');
      },
      audioMixingStateChanged: (
        AudioMixingStateCode state,
        AudioMixingReason reason,
      ) {
        print(
            'audioMixingStateChanged state:${state.toString()}, reason: ${reason.toString()}}');
      },
      remoteAudioMixingBegin: () {
        //TODO: 원격 북소리 시작될 때 제어
        // print('remoteAudioMixingBegin');
      },
      remoteAudioMixingEnd: () {
        //TODO: 원격 북소리 끝났을 때 제어
        // print('remoteAudioMixingEnd');
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Audio quickstart',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Agora Audio quickstart'),
          actions: [
            IconButton(
                onPressed: () async {
                  // 새로 눌릴때마다 오디오 처음으로 돌리도록 설정
                  _engine.setAudioMixingPosition(0);

                  // 북소리 시작하는 함수. mp3 파일 저장된 경로를 p에 담아서 넘겨주기
                  _engine.startAudioMixing(p, false, true, 1);
                },
                icon: Icon(Icons.local_fire_department_rounded)),
            IconButton(
                onPressed: () async {
                  // 녹음 시작
                  // 아이폰 '파일' 앱에서 저장된 파일 확인하기
                  Directory dir = await getApplicationDocumentsDirectory();
                  String filePath = path.join(dir.path, "audio.wav");
                  var config = AudioRecordingConfiguration(
                    filePath,
                  );

                  // 녹음 하고 저장하는 함수
                  await _engine.startAudioRecordingWithConfig(
                    config,
                  );
                },
                icon: Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                )),
            IconButton(
                onPressed: () async {
                  // 녹음 끝
                  await _engine.stopAudioRecording();
                },
                icon: Icon(
                  Icons.stop,
                )),
          ],
        ),
        body: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () async {
                  // 아래 두 줄 쓰면 목소리는 죽이고, 북소리만 키워줌
                  await _engine.adjustRecordingSignalVolume(0);
                  await _engine.adjustAudioMixingVolume(50);
                },
                icon: Icon(Icons.music_off_outlined)),
            IconButton(
                onPressed: () async {
                  // 목소리 볼륨 키워주기
                  await _engine.adjustRecordingSignalVolume(50);
                },
                icon: Icon(Icons.volume_up)),
          ]),
        ),
      ),
    );
  }
}
