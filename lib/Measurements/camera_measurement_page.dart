import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'measurement_display_page.dart';

class CameraMeasurementPage extends StatefulWidget {
  final double userHeight;

  const CameraMeasurementPage({super.key, required this.userHeight});

  @override
  State<CameraMeasurementPage> createState() => _CameraMeasurementPageState();
}

class _CameraMeasurementPageState extends State<CameraMeasurementPage> {
  CameraController? _cameraController;
  bool _isCapturing = false;
  bool _processingImage = false;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  int _timerDuration = 0;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        if (mounted) {
          _showErrorDialog('No cameras found');
        }
        return;
      }
      _selectedCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      await _initCameraController(_cameras![_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error initializing camera: $e');
      }
    }
  }

  Future<void> _initCameraController(
    CameraDescription cameraDescription,
  ) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      if (mounted) {
        _showErrorDialog('Camera error: ${e.description}');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _cancelTimer();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initCameraController(_cameras![_selectedCameraIndex]);
  }

  void _startTimer() {
    _cancelTimer();
    if (mounted) {
      setState(() {
        _isCapturing = true;
        _timerDuration = 5;
      });
    }
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timerDuration > 0) {
          _timerDuration--;
        } else {
          timer.cancel();
          _captureImage();
        }
      });
    });
  }

  void _cancelTimer() {
    _captureTimer?.cancel();
    _captureTimer = null;
    if (mounted) {
      setState(() {
        _isCapturing = false;
        _timerDuration = 0;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _processingImage) {
      return;
    }

    if (mounted) {
      setState(() {
        _processingImage = true;
      });
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MeasurementDisplayPage(
                imagePath: photo.path,
                userHeight: widget.userHeight,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error capturing image: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingImage = false;
          _isCapturing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Body Measurement',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Position your full body in this frame\nStand approximately 6 feet away',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _isCapturing ? null : _switchCamera,
                ),
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.timer, color: Colors.white, size: 30),
                  onPressed: _isCapturing ? null : _startTimer,
                ),
              ],
            ),
          ),
          if (_isCapturing)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    '$_timerDuration',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCapturing)
                  ElevatedButton(
                    onPressed: _cancelTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _processingImage ? null : _captureImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 150, 151),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        _processingImage
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Capture Measurements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Height: ${widget.userHeight.toStringAsFixed(1)} inches',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
