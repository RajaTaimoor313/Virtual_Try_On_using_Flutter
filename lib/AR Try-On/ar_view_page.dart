// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARViewPage extends StatefulWidget {
  final String modelPath;
  final double scale;
  final double rotationAngle;

  const ARViewPage({
    super.key,
    required this.modelPath,
    this.scale = 0.2,
    this.rotationAngle = -90.0,
  });

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  ARNode? _jacketNode;
  bool _isInitialized = false;
  bool _isPlacingJacket = false;
  bool _isJacketPlaced = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _timeoutOccurred = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_isInitialized && !_hasError) {
        setState(() {
          _timeoutOccurred = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Try-On'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (!_hasError)
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
          if (!_isInitialized && !_hasError && !_timeoutOccurred)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Initializing AR...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (_timeoutOccurred && !_isInitialized && !_hasError)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 50),
                    const SizedBox(height: 20),
                    const Text(
                      'AR initialization is taking longer than expected.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please check if your device supports AR.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _timeoutOccurred = false;
                        });
                      },
                      child: const Text(
                        'Keep Waiting',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasError)
            Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AR Features Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'We couldn\'t initialize AR on your device.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back to Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            7,
                            150,
                            151,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isInitialized && !_hasError)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (!_isJacketPlaced)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Move your camera to scan your surroundings. Tap on a surface to place the item.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.replay,
                        label: 'Reset',
                        onPressed: _onReset,
                        color: Colors.red,
                      ),
                      if (_isJacketPlaced)
                        _buildActionButton(
                          icon: Icons.check_circle,
                          label: 'Looking Good!',
                          onPressed: () => Navigator.pop(context),
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    try {
      _arSessionManager!
          .onInitialize(
            showFeaturePoints: true,
            showPlanes: true,
            customPlaneTexturePath: "assets/triangle.png",
            showWorldOrigin: false,
            handlePans: true,
            handleRotation: true,
          )
          .then((_) {
            _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
            _arObjectManager!.onNodeTap = _onNodeTapped;
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _startPlacementMode();
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Initialization error: $error';
              });
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error creating AR view: $e';
        });
      }
    }
  }

  void _startPlacementMode() {
    setState(() {
      _isPlacingJacket = true;
    });
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hits) async {
    if (!_isPlacingJacket || _isJacketPlaced || hits.isEmpty) return;

    var hit = hits.firstWhere(
      (hit) => hit.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    if (_jacketNode != null) {
      await _arObjectManager!.removeNode(_jacketNode!);
      _jacketNode = null;
    }

    final scale = vector.Vector3(widget.scale, widget.scale, widget.scale);
    final rotationRadians = widget.rotationAngle * (3.14159 / 180.0);

    try {
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: widget.modelPath,
        scale: scale,
        position: hit.worldTransform.getTranslation(),
        rotation: vector.Vector4(1.0, 0.0, 0.0, rotationRadians),
      );

      _jacketNode = newNode;
      await _arObjectManager!.addNode(_jacketNode!);

      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      bool? didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
      if (didAddAnchor == true) {
        _jacketNode!.position = anchor.transformation.getTranslation();
      }

      setState(() {
        _isJacketPlaced = true;
        _isPlacingJacket = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onNodeTapped(List<String> nodeNames) {}

  Future<void> _onReset() async {
    if (_jacketNode != null) {
      await _arObjectManager!.removeNode(_jacketNode!);
      _jacketNode = null;
    }
    setState(() {
      _isJacketPlaced = false;
      _isPlacingJacket = false;
    });
    _startPlacementMode();
  }
}
