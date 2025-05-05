// ignore_for_file: use_build_context_synchronously

import 'package:clothify/persistent_bottom_nav.dart';
import 'package:clothify/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'camera_measurement_page.dart';
import 'edit_measurements_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  bool _isLoading = true;
  Map<String, double>? _measurements;
  String _currentUnit = 'pixels';
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkMeasurements();
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _checkMeasurements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        final hasMeasurements = await ApiService.hasMeasurements(
          currentUser.id!,
        );

        if (hasMeasurements) {
          final measurements = await ApiService.getUserMeasurements(
            currentUser.id!,
            unit: _currentUnit,
          );

          if (mounted) {
            setState(() {
              _measurements =
                  measurements != null
                      ? Map<String, double>.from(measurements)
                      : null;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _measurements = null;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _measurements = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking measurements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleUnit() async {
    _currentUnit = _currentUnit == 'pixels' ? 'inches' : 'pixels';
    await _checkMeasurements();
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

  String _getUnitText() {
    return _currentUnit;
  }

  Future<void> _deleteMeasurements() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser != null && currentUser.id != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Measurements'),
                content: const Text(
                  'Are you sure you want to delete your measurements?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );

        if (confirm == true) {
          setState(() {
            _isLoading = true;
          });

          final success = await ApiService.deleteMeasurements(currentUser.id!);

          if (success) {
            userProvider.setMeasurementsAvailable(false);

            if (mounted) {
              setState(() {
                _measurements = null;
                _isLoading = false;
              });

              Fluttertoast.showToast(
                msg: "Measurements deleted successfully",
                backgroundColor: Colors.green,
              );
            }
          } else {
            throw Exception("Failed to delete measurements");
          }
        }
      }
    } catch (e) {
      print('Error deleting measurements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(
          msg: "Failed to delete measurements",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _showHeightInputDialog() async {
    _heightController.text = '';

    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Your Height'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please enter your height in inches for more accurate measurements.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Height (inches)',
                    hintText: 'e.g., 68.5 for 5\'8.5"',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'For reference:\n5\'0" = 60 inches\n5\'6" = 66 inches\n6\'0" = 72 inches',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final heightText = _heightController.text.trim();
                  if (heightText.isEmpty) {
                    Fluttertoast.showToast(
                      msg: "Please enter your height",
                      backgroundColor: Colors.red,
                    );
                    return;
                  }

                  final height = double.tryParse(heightText);
                  if (height == null || height < 36 || height > 96) {
                    Fluttertoast.showToast(
                      msg: "Please enter a valid height (36-96 inches)",
                      backgroundColor: Colors.red,
                    );
                    return;
                  }

                  Navigator.pop(context, height);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraMeasurementPage(userHeight: result),
        ),
      ).then((_) {
        _checkMeasurements();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNav(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFF000A3D),
        appBar: AppBar(
          title: const Text('Body Measurements'),
          backgroundColor: const Color(0xFFECECEC),
          foregroundColor: Colors.black,
          elevation: 0,
          actions:
              _measurements != null
                  ? [
                    TextButton(
                      onPressed: _toggleUnit,
                      child: Text(
                        _currentUnit == 'pixels'
                            ? 'Show Inches'
                            : 'Show Pixels',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 7, 150, 151),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                  : null,
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _measurements == null
                ? _buildNoMeasurementsView()
                : _buildMeasurementsView(),
      ),
    );
  }

  Widget _buildNoMeasurementsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten, size: 100, color: Colors.white),
          const SizedBox(height: 30),
          const Text(
            'Give us Your Measurements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We\'ll use your camera to detect your body measurements for the perfect fit.\n Stand away so that your upper body fit in the Camera for better results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _showHeightInputDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 150, 151),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Give',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Body Measurements (${_getUnitText()})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'These measurements help us provide better fitting recommendations',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children:
                    _measurements!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMeasurementName(entry.key),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${entry.value.toStringAsFixed(1)} ${_getUnitText()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditMeasurementsPage(
                              initialMeasurements: _measurements!,
                              unit: _currentUnit,
                            ),
                      ),
                    ).then((_) => _checkMeasurements());
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _deleteMeasurements,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
