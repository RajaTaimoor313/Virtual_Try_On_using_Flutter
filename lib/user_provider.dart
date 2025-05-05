import 'package:clothify/Measurements/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'package:clothify/database_helper.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isMeasurementsAvailable = false;
  Map<String, dynamic>? _styleProfile;

  final String _backendUrl = 'http://192.168.1.75:3000';

  User? get currentUser => _currentUser;
  bool get isMeasurementsAvailable => _isMeasurementsAvailable;
  Map<String, dynamic>? get styleProfile => _styleProfile;

  UserProvider() {
    _loadUser();
  }

  Future<bool> checkBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/api/style-ai/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection check failed: $e');
      return false;
    }
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');

      if (userId != null && userName != null && userEmail != null) {
        _currentUser = User(id: userId, name: userName, email: userEmail);
        if (_currentUser?.id != null) {
          _isMeasurementsAvailable = await ApiService.hasMeasurements(
            _currentUser!.id!,
          );
          await loadStyleProfile();
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> setUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);

      _currentUser = user;
      if (_currentUser?.id != null) {
        _isMeasurementsAvailable = await ApiService.hasMeasurements(
          _currentUser!.id!,
        );
        await loadStyleProfile();
      }
      notifyListeners();
    } catch (e) {
      print('Error setting user: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');

      _currentUser = null;
      _isMeasurementsAvailable = false;
      _styleProfile = null;
      notifyListeners();
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  void setMeasurementsAvailable(bool available) {
    _isMeasurementsAvailable = available;
    notifyListeners();
  }

  Future<void> checkMeasurementsAvailability() async {
    if (_currentUser?.id != null) {
      try {
        _isMeasurementsAvailable = await ApiService.hasMeasurements(
          _currentUser!.id!,
        );
        notifyListeners();
      } catch (e) {
        print('Error checking measurements availability: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> loadStyleProfile() async {
    if (_currentUser?.id == null) return null;
    try {
      bool isBackendAvailable = await checkBackendConnection();
      if (isBackendAvailable) {
        try {
          final response = await http
              .get(
                Uri.parse(
                  '$_backendUrl/api/style-ai/profile/${_currentUser!.id}',
                ),
              )
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['data'] != null) {
              _styleProfile = data['data'];
              notifyListeners();
              return _styleProfile;
            }
          } else {
            print('API returned error status: ${response.statusCode}');
          }
        } catch (e) {
          print('Error getting style profile from API: $e');
        }
      }

      try {
        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;
        final tableCheck = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='user_style_preferences'",
        );
        if (tableCheck.isEmpty) return null;

        final results = await db.query(
          'user_style_preferences',
          where: 'user_id = ?',
          whereArgs: [_currentUser!.id],
        );

        if (results.isNotEmpty) {
          final styleData = results.first['style_data'] as String?;
          if (styleData != null) {
            try {
              final styleDataMap = json.decode(styleData);
              _styleProfile = styleDataMap;
              notifyListeners();
              return _styleProfile;
            } catch (e) {
              print('Error parsing JSON from local database: $e');
              return null;
            }
          }
        }
      } catch (dbError) {
        print('Error accessing local database: $dbError');
      }
      return null;
    } catch (e) {
      print('Error loading style profile: $e');
      return null;
    }
  }

  Future<bool> saveStyleProfile(Map<String, dynamic> styleProfile) async {
    if (_currentUser?.id == null) return false;
    try {
      bool isBackendAvailable = await checkBackendConnection();
      if (isBackendAvailable) {
        try {
          final response = await http
              .post(
                Uri.parse('$_backendUrl/api/style-ai/profile'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'userId': _currentUser!.id,
                  'styleProfile': styleProfile,
                }),
              )
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            _styleProfile = styleProfile;
            notifyListeners();
          } else {
            print('Backend returned error status: ${response.statusCode}');
            print('Response: ${response.body}');
          }
        } catch (e) {
          print('Error saving style profile to API: $e');
        }
      }

      _styleProfile = styleProfile;
      try {
        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;
        final tableCheck = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='user_style_preferences'",
        );
        if (tableCheck.isEmpty) {
          await db.execute('''
            CREATE TABLE user_style_preferences (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              style_type TEXT NOT NULL,
              style_data TEXT,
              taken_at TEXT NOT NULL
            )
          ''');
        }

        final data = {
          'user_id': _currentUser!.id,
          'style_type': styleProfile['style'],
          'style_data': json.encode(styleProfile),
          'taken_at': DateTime.now().toIso8601String(),
        };

        final existing = await db.query(
          'user_style_preferences',
          where: 'user_id = ?',
          whereArgs: [_currentUser!.id],
        );

        if (existing.isNotEmpty) {
          await db.update(
            'user_style_preferences',
            data,
            where: 'user_id = ?',
            whereArgs: [_currentUser!.id],
          );
        } else {
          await db.insert('user_style_preferences', data);
        }
      } catch (dbError) {
        print('Error saving to local database: $dbError');
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving style profile: $e');
      return false;
    }
  }
}
