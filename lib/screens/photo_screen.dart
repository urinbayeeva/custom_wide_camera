import 'dart:io';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PhotoScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const PhotoScreen({super.key, required this.cameras});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late CameraController controller;
  bool isCaptured = false;
  int _selectedCameraIndex = 0;
  bool isFlash = false;
  File? _capturedImage;
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _initCamera(int cameraIndex) async {
    controller = CameraController(
        widget.cameras[cameraIndex], ResolutionPreset.ultraHigh,
        fps: 120);

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  void _toggleFlashLight() {
    if (isFlash) {
      controller.setFlashMode(FlashMode.off);
      setState(() {
        isFlash = false;
      });
    } else {
      controller.setFlashMode(FlashMode.torch);
      setState(() {
        isFlash = true;
      });
    }
  }

  void switchCamera() async {
    if (controller != null) {
      await controller.dispose();
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  void capturePhoto() async {
    if (!controller.value.isInitialized) {
      return;
    }

    final Directory appDir = await getApplicationSupportDirectory();
    final String capturePath = path.join(appDir.path, '${DateTime.now()}.jpg');

    if (controller.value.isTakingPicture) {
      return;
    }

    try {
      setState(() {
        isCaptured = true;
      });
      final XFile capturedImage = await controller.takePicture();
      String imagePath = capturedImage.path;
      await GallerySaver.saveImage(imagePath);

      audioPlayer.open(Audio("assets/camer_shutter.mp3"));
      audioPlayer.play();

      setState(() {
        _capturedImage = File(imagePath);
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isCaptured = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Expanded(
          flex: 1,
          child: new CameraPreview(controller),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 60,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: SvgPicture.asset("assets/return.svg"),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      _toggleFlashLight();
                    },
                    child: SvgPicture.asset("assets/flash.svg"),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 150,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          switchCamera();
                        },
                        child: Image.asset("assets/flip.png", scale: 5),
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () {
                          capturePhoto();
                        },
                        child: SvgPicture.asset("assets/take_photo.svg"),
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () {},
                        child: _capturedImage != null
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8)),
                                child: Image.file(
                                  _capturedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset("assets/saved.png", scale: 5),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 160,
          top: 120,
          child: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: Text(
                    "2x",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: Text(
                    "1x",
                    style: TextStyle(color: Color(0xFFFFD50B), fontSize: 12),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: Text(
                    "0.5x",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
