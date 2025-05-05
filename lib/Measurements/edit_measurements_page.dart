import 'package:clothify/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class EditMeasurementsPage extends StatefulWidget {
  final Map<String, double> initialMeasurements;
  final String unit;

  const EditMeasurementsPage({
    Key? key,
    required this.initialMeasurements,
    required this.unit,
  }) : super(key: key);

  @override
  State<EditMeasurementsPage> createState() => _EditMeasurementsPageState();
}

class _EditMeasurementsPageState extends State<EditMeasurementsPage> {
  late Map<String, TextEditingController> _controllers;
  bool _isSaving = false;
  late String _currentUnit;

  @override
  void initState() {
    super.initState();
    _currentUnit = widget.unit;
    _controllers = {};
    widget.initialMeasurements.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toStringAsFixed(1));
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        return key.replaceAll('_', ' ').capitalize();
    }
  }

  Future<void> _saveMeasurements() async {
    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null ||
          userProvider.currentUser!.id == null) {
        Fluttertoast.showToast(
          msg: "You need to be logged in to save measurements",
          backgroundColor: Colors.red,
        );
        return;
      }

      final userId = userProvider.currentUser!.id!;
      final measurements = <String, double>{};
      _controllers.forEach((key, controller) {
        measurements[key] = double.tryParse(controller.text) ?? 0.0;
      });

      final success = await ApiService.updateMeasurements(
        userId,
        measurements,
        _currentUnit,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: "Measurements updated successfully!",
          backgroundColor: Colors.green,
        );
        userProvider.setMeasurementsAvailable(true);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception("Failed to update measurements");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving measurements: $e",
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
        title: Text('Edit Measurements ($_currentUnit)'),
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Your Measurements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are editing measurements in $_currentUnit. '
                    'Adjust as needed for better fitting recommendations.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  ..._controllers.entries.map((entry) {
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Save Changes',
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
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
