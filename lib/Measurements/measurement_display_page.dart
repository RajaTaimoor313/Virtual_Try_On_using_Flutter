import 'package:clothify/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'api_service.dart';

class MeasurementDisplayPage extends StatefulWidget {
  final String imagePath;
  final double userHeight;

  const MeasurementDisplayPage({
    super.key,
    required this.imagePath,
    required this.userHeight,
  });

  @override
  State<MeasurementDisplayPage> createState() => _MeasurementDisplayPageState();
}

class _MeasurementDisplayPageState extends State<MeasurementDisplayPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentUnit = 'pixels';

  Map<String, double> _pixelMeasurements = {};
  Map<String, double> _inchMeasurements = {};

  final Map<String, TextEditingController> _pixelControllers = {};
  final Map<String, TextEditingController> _inchControllers = {};

  @override
  void initState() {
    super.initState();
    _processMeasurements();
  }

  @override
  void dispose() {
    _disposeControllers(_pixelControllers);
    _disposeControllers(_inchControllers);
    super.dispose();
  }

  void _disposeControllers(Map<String, TextEditingController> controllers) {
    controllers.forEach((_, controller) => controller.dispose());
    controllers.clear();
  }

  Future<void> _processMeasurements() async {
    setState(() => _isLoading = true);

    try {
      _pixelMeasurements = {
        'chest': 142.8,
        'waist': 122.4,
        'shoulder_width': 68.0,
        'left_arm_length': 170.0,
        'right_arm_length': 170.0,
        'neck_circumference': 70.5,
      };

      final ratio =
          widget.userHeight / (4.6 * _pixelMeasurements['shoulder_width']!);
      _inchMeasurements = {
        for (var key in _pixelMeasurements.keys)
          key: (_pixelMeasurements[key]! * ratio).roundToDouble(),
      };

      _createMeasurementControllers();
    } catch (_) {
      _setupDefaultMeasurements();
      _createMeasurementControllers();

      Fluttertoast.showToast(
        msg: "Error processing measurements. You can enter them manually.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupDefaultMeasurements() {
    final keys = [
      'chest',
      'waist',
      'shoulder_width',
      'left_arm_length',
      'right_arm_length',
      'neck_circumference',
    ];

    _pixelMeasurements = {for (var k in keys) k: 0.0};
    _inchMeasurements = {for (var k in keys) k: 0.0};
  }

  void _createMeasurementControllers() {
    _disposeControllers(_pixelControllers);
    _disposeControllers(_inchControllers);

    _pixelMeasurements.forEach((k, v) {
      _pixelControllers[k] = TextEditingController(text: v.toStringAsFixed(1));
    });

    _inchMeasurements.forEach((k, v) {
      _inchControllers[k] = TextEditingController(text: v.toStringAsFixed(1));
    });
  }

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == 'pixels' ? 'inches' : 'pixels';
    });
  }

  String _getMeasurementName(String key) {
    switch (key) {
      case 'chest':
        return 'Chest Size';
      case 'waist':
        return 'Waist Size';
      case 'shoulder_width':
        return 'Shoulder Width';
      case 'left_arm_length':
        return 'Left Arm Length';
      case 'right_arm_length':
        return 'Right Arm Length';
      case 'neck_circumference':
        return 'Neck Circumference';
      default:
        return StringExtension(key.replaceAll('_', ' ')).capitalize();
    }
  }

  void _updateMeasurementsFromControllers() {
    final source =
        _currentUnit == 'pixels' ? _pixelControllers : _inchControllers;
    final target =
        _currentUnit == 'pixels' ? _pixelMeasurements : _inchMeasurements;

    source.forEach((key, controller) {
      target[key] = _parseDouble(controller.text, target[key] ?? 0.0);
    });
  }

  double _parseDouble(String value, double fallback) {
    return double.tryParse(value) ?? fallback;
  }

  Future<void> _saveMeasurements() async {
    setState(() => _isSaving = true);

    try {
      _updateMeasurementsFromControllers();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.currentUser?.id == null) {
        Fluttertoast.showToast(
          msg: "You need to be logged in to save measurements",
          backgroundColor: Colors.red,
        );
        return;
      }

      final success = await ApiService.saveMeasurements(
        userProvider.currentUser!.id!,
        _pixelMeasurements,
        _inchMeasurements,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: "Measurements saved successfully!",
          backgroundColor: Colors.green,
        );
        userProvider.setMeasurementsAvailable(true);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("Failed to save measurements");
      }
    } catch (_) {
      Fluttertoast.showToast(
        msg: "Error saving measurements",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A3D),
      appBar: AppBar(
        title: const Text('Your Measurements'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _toggleUnit,
              child: Text(
                _currentUnit == 'pixels' ? 'See in Inches' : 'See in Pixels',
                style: const TextStyle(
                  color: Color.fromARGB(255, 7, 150, 151),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Processing your measurements...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Review Your Measurements',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _currentUnit == 'pixels'
                                      ? 'Pixels'
                                      : 'Inches',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUnit == 'pixels'
                                ? 'These measurements are in pixels. Press "See in Inches" to view in standard units.'
                                : 'These measurements are converted to inches based on your height. Feel free to adjust them for accuracy.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.height,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Height',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${widget.userHeight.toStringAsFixed(1)} inches',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (widget.imagePath.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Captured Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 200,
                                    child: Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ..._getCurrentControllers().entries.map((entry) {
                            return _buildMeasurementField(
                              _getMeasurementName(entry.key),
                              entry.value,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFFECECEC),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMeasurements,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 150, 151),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child:
                          _isSaving
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Save Measurements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
    );
  }

  Map<String, TextEditingController> _getCurrentControllers() {
    return _currentUnit == 'pixels' ? _pixelControllers : _inchControllers;
  }

  Widget _buildMeasurementField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    _currentUnit,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
