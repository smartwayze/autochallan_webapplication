import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final image = await _cameraController!.takePicture();
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = "${directory.path}/violation_${DateTime.now().millisecondsSinceEpoch}.jpg";
    File(image.path).copy(imagePath);

    setState(() {
      _imagePath = imagePath;
    });

    // You can now send this image to your backend server.
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Capture Violation")),
      body: Column(
        children: [
          _isCameraInitialized
              ? AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          )
              : Center(child: CircularProgressIndicator()),
          ElevatedButton(
            onPressed: _captureImage,
            child: Text("Capture Violation"),
          ),
          if (_imagePath != null) Image.file(File(_imagePath!)),
        ],
      ),
    );
  }
}
