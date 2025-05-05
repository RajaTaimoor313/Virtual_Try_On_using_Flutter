import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = 'http://192.168.1.75:3000';

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString('server_url');
      if (storedUrl != null && storedUrl.isNotEmpty) {
        baseUrl = storedUrl;
      }
    } catch (e) {
      print('Error initializing ApiService: $e');
    }
  }

  static Future<void> updateServerUrl(String newUrl) async {
    try {
      if (newUrl.isEmpty) return;
      if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
        newUrl = 'http://$newUrl';
      }
      final testUrl = '$newUrl/api/measurements/health';
      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', newUrl);
        baseUrl = newUrl;
      } else {
        throw Exception('Server not responding correctly');
      }
    } catch (e) {
      print('Error updating server URL: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> processMeasurementImage(
    File imageFile,
    double heightInches,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/measurements/process-image'),
      );
      request.fields['height'] = heightInches.toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          if (data['pixelMeasurements'] is Map) {
            data['pixelMeasurements'] = _convertMeasurementsToDoubles(
              data['pixelMeasurements'],
            );
          }
          if (data['inchMeasurements'] is Map) {
            data['inchMeasurements'] = _convertMeasurementsToDoubles(
              data['inchMeasurements'],
            );
          }
        }
        return jsonResponse;
      } else {
        throw Exception('Failed to process image: ${response.body}');
      }
    } catch (e) {
      print('Error in processMeasurementImage: $e');
      rethrow;
    }
  }

  static Map<String, double> _convertMeasurementsToDoubles(Map measurements) {
    return measurements.map((key, value) {
      if (value is double) return MapEntry(key, value);
      if (value is int) return MapEntry(key, value.toDouble());
      if (value is String) {
        return MapEntry(key, double.tryParse(value) ?? 0.0);
      }
      return MapEntry(key, 0.0);
    }).cast<String, double>();
  }

  static Future<bool> saveMeasurements(
    int userId,
    Map<String, double> pixelMeasurements,
    Map<String, double> inchMeasurements,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/measurements/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'pixelMeasurements': pixelMeasurements.map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
          'inchMeasurements': inchMeasurements.map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to save measurements: ${response.body}');
      }
    } catch (e) {
      print('Error in saveMeasurements: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserMeasurements(
    int userId, {
    String unit = 'pixels',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/measurements/user/$userId?unit=$unit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _convertMeasurementsToDoubles(data['data'] ?? {});
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get measurements: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserMeasurements: $e');
      return null;
    }
  }

  static Future<bool> updateMeasurements(
    int userId,
    Map<String, double> measurements,
    String unit,
  ) async {
    try {
      final Map<String, dynamic> payload = {'unit': unit};

      if (unit == 'pixels') {
        payload['pixelMeasurements'] = measurements.map(
          (key, value) => MapEntry(key, value.toDouble()),
        );
      } else {
        payload['inchMeasurements'] = measurements.map(
          (key, value) => MapEntry(key, value.toDouble()),
        );
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/measurements/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateMeasurements: $e');
      return false;
    }
  }

  static Future<bool> deleteMeasurements(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/measurements/user/$userId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteMeasurements: $e');
      return false;
    }
  }

  static Future<bool> hasMeasurements(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/measurements/has-measurements/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasMeasurements'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error in hasMeasurements: $e');
      return false;
    }
  }

  static Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/measurements/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }
}
