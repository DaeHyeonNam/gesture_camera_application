
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'preview_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State with WidgetsBindingObserver{

  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  bool isWindowShown = false;
  String imgPath;

  bool videoSelected = false;
  bool videoRecordStart = false;
  bool videoPaused = false;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  double s = 1.01;
  bool is3sec = false;
  bool is5sec = false;
  bool thumbnailFilled = false;
  String centerText = "";

  String identifiedGesture= "";

  //socket connection
  int port = 9008;
  String msg = ""; // received message
  Socket clientSocket;

  @override
  void initState() {
    connectToServer();
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 1;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  void connectToServer() async {
    print("Destination Address: 192.168.43.112");

    Socket.connect("192.168.0.9", port, timeout: Duration(seconds: 5))
        .then((socket) {
      setState(() {
        clientSocket = socket;
      });

      socket.listen(
            (onData) {
          setState(() {
            msg=String.fromCharCodes(onData).trim();
            if(msg == "timer 3s")
              timer3sClicked();
            else if(msg == "timer 5s")
              timer5sClicked();
            else if(msg == "zoom in"){
              setState(() {
                s += 0.2;
                if(s > 2.1){
                  s = 2.01;
                }
              });
            }
            else if(msg == "zoom out"){
              setState(() {
                s -= 0.2;
                if(s < 1){
                  s = 1.01;
                }
              });
            }
            else if(msg == "switch"){
              setState(() {
                videoSelected=videoSelected? false: true;
              });
            }
            else if(msg == "resume" && videoRecordStart){
              if(videoPaused && controller.value.isRecordingPaused){
                onResumeButtonPressed();
                setState(() {
                  videoPaused = false;
                });
              }
              else{
                onPauseButtonPressed();
                setState(() {
                  videoPaused = true;
                });
              }
            }
            else if(msg == "capture"){
              if(videoSelected){
                if(videoRecordStart){
                  if(controller != null && controller.value.isInitialized && controller.value.isRecordingVideo) {
                    onStopButtonPressed();
                    setState(() {
                      videoRecordStart = false;
                    });
                  }
                }
                else {
                  if (is3sec)
                    timer3s();
                  else if (is5sec)
                    timer5s();
                  else
                    noTimer();
                }
              }
              else{
                if (is3sec)
                  timer3s();
                else if (is5sec)
                  timer5s();
                else
                  noTimer();
              }
            }
          });
        },
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        _initCameraController(controller.description);
      }
    }
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Stack(
                    children: <Widget>[
                      GestureDetector(
                          onTap: (){
                            if(isWindowShown){
                              setState(() {
                                isWindowShown = false;
                              });
                            }
                          },
                          child: _cameraPreviewWidget()
                      ),
                      Align(
                        alignment: FractionalOffset.center,
                        child: Text(centerText,style: TextStyle( color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 60),),
                      ),
                      Align(
                        alignment: FractionalOffset.topLeft,
                        child: Container(
                          height: 70,
                          width: 70,
                          child: IconButton(
                              icon:IconButton(icon: Icon(Icons.timer, size: 30, color: is3sec || is5sec? Colors.blue: Colors.black45), onPressed: (){
                                setState(() {
                                  isWindowShown = isWindowShown ? false: true;
                                });
                              },)
                          ),
                        ),
                      ),
                      isWindowShown ? Container(
                          margin:  EdgeInsets.fromLTRB(55.0, 15.0, 50.0, 0.0),
                          width: 100,
                          height: 40,
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              GestureDetector(
                                onTap: timer3sClicked,
                                child:Text(
                                  "3s",
                                  style: TextStyle(
                                      color: is3sec ? Colors.blue: Colors.black45,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold
                                  )
                                )
                              ),
                              GestureDetector(
                                onTap: timer5sClicked,
                                child: Text(
                                  "5s",
                                  style: TextStyle(
                                      color: is5sec ? Colors.blue: Colors.black45,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ],
                          )
                      ):Container(),

                      Align(
                        alignment: FractionalOffset.bottomRight,
                        child: Container(
                          height: 130,
                          width: 100,
                          child: Column(
                            children: <Widget>[
                              IconButton(
                                  icon: IconButton(icon: Icon(Icons.zoom_in, size: 32,), color: Colors.black45, onPressed:(){
                                    setState(() {
                                      s += 0.2;
                                      if(s > 2.1){
                                        s = 2.01;
                                      }
                                    });
                                  })
                              ),
                              IconButton(
                                  icon: IconButton(icon: Icon(Icons.zoom_out, size: 32,), color: Colors.black45, onPressed:(){
                                    setState(() {
                                      s -= 0.2;
                                      if(s < 1){
                                        s = 1.01;
                                      }
                                    });
                                  })
                              )
                            ],
                          ),
                        ),
                      ),
                    ]
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
//                      _cameraToggleRowWidget()
                      videoRecordStart? _recordResumeWidget():
                      thumbnailFilled? _thumbnailWidget() : Container(width: 85,),
                      videoSelected? _recordControlWidget():_cameraControlWidget(),
                      videoSelected? _cameraControlWidget(): _recordControlWidget(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  void timer3sClicked(){
    setState(() {
      if(is5sec) {
        is5sec = false;
      }
      if(is3sec){
        is3sec = false;
      }
      else
        is3sec = true;
    });
  }
  void timer5sClicked(){
    setState(() {
      if(is3sec) {
        is3sec = false;
      }
      if(is5sec){
        is5sec = false;
      }
      else
        is5sec = true;
    });
  }

  Widget _recordResumeWidget(){
    return GestureDetector(
      onTap: () {
        if(videoPaused && controller.value.isRecordingPaused){
          onResumeButtonPressed();
          setState(() {
            videoPaused = false;
          });
        }
        else{
          onPauseButtonPressed();
          setState(() {
            videoPaused = true;
          });
        }
      },
      child: new Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(width: 2, color: Colors.white)),
            child: Icon(
              videoPaused? Icons.play_arrow: Icons.pause,
              color: Colors.white,
              size: 24,
            ),
          )),
    );
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return Transform.scale(
      scale: s,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _recordControlWidget(){
    return GestureDetector(
      onTap: () {
        if(videoSelected){
          if(videoRecordStart){
            if(controller != null && controller.value.isInitialized && controller.value.isRecordingVideo) {
              onStopButtonPressed();
              setState(() {
                videoRecordStart = false;
              });
            }
          }
          else {
            if (is3sec)
              timer3s();
            else if (is5sec)
              timer5s();
            else
              noTimer();
          }

        }
        else
          setState(() {
            videoSelected=true;
          });
        //Navigator.of(context).pop();

      },
      child: new Align(
          alignment: Alignment.center,
          child: Container(
            margin: videoSelected? EdgeInsets.all(0): EdgeInsets.all(20),
            padding: videoSelected? EdgeInsets.all(4): EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: videoSelected? Colors.white: Colors.black,
                borderRadius: videoSelected? BorderRadius.circular(300): BorderRadius.circular(100),
                border: Border.all(width: 2, color: Colors.white)),
            child: Icon(
              videoSelected? videoRecordStart? Icons.stop: Icons.fiber_manual_record: Icons.videocam,
              color: videoSelected? Colors.red: Colors.white,
              size: videoSelected? 50: 24,
            ),
          )),
    );
  }

  Widget _cameraControlWidget() {
    return GestureDetector(
      onTap: () {
        if(videoSelected)
          setState(() {
            videoSelected = false;
          });
        else {
          if (is3sec)
            timer3s();
          else if (is5sec)
            timer5s();
          else
            noTimer();
        }
      },
      child: new Align(
          alignment: Alignment.center,
          child: Container(
            margin: videoSelected? EdgeInsets.all(20): EdgeInsets.all(0),
            padding: videoSelected? EdgeInsets.all(10): EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: videoSelected? Colors.black: Colors.white,
                borderRadius: videoSelected? BorderRadius.circular(100): BorderRadius.circular(300),
                border: Border.all(width: 2, color: Colors.white)),
            child: Icon(
              Icons.camera,
              color: videoSelected? Colors.white: Colors.black,
              size: videoSelected? 24: 28,
            ),
          )),
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onCapturePressed() async {
    try {
      final path =
      join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await controller.takePicture(path);
      imgPath = path;

      Get.toNamed("preview", arguments: [imgPath, s]);
      Future.delayed(Duration(seconds: 2), (){
        Get.back();
      });
    } catch (e) {
      _showCameraException(e);
    }
    setState(() {
      thumbnailFilled = true;
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }



  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> startVideoRecording() async {

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    setState(() {
      thumbnailFilled = true;
    });
    await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
    VideoPlayerController.file(File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(false);
    await vcontroller.initialize();
//    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imgPath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return videoController == null && imgPath == null
        ? Container()
        : SizedBox(
      child: (imgPath != null)
          ? Image.file(File(imgPath))
          : Container(
        child: Center(
          child: AspectRatio(
              aspectRatio:
              videoController.value.size != null
                  ? videoController.value.aspectRatio
                  : 1.0,
              child: VideoPlayer(videoController)),
        ),
      ),
      width: 87.0,
      height: 64.0,
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void timer3s(){
    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        centerText = "3";
      });
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        centerText = "2";
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        centerText = "1";
      });
    });
    Future.delayed(const Duration(seconds: 3), () {

      setState(() {
        centerText = "0";
        videoSelected? onVideoRecordButtonPressed(): _onCapturePressed();
        if(videoSelected){
          videoRecordStart = true;
        }
        centerText = "";
      });
    });
  }

  void timer5s(){
    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        centerText = "5";
      });
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        centerText = "4";
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        centerText = "3";
      });
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        centerText = "2";
      });
    });
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        centerText = "1";
      });
    });
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        centerText = "0";
        videoSelected? onVideoRecordButtonPressed(): _onCapturePressed();
        if(videoSelected){
          videoRecordStart = true;
        }
        centerText = "";
      });
    });
  }

  void noTimer(){
    videoSelected? onVideoRecordButtonPressed(): _onCapturePressed();
    setState(() {
      if(videoSelected){
        videoRecordStart = true;
        centerText = "";
      }
    });
  }
}