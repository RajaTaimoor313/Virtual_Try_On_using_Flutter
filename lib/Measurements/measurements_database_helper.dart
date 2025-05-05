import 'package:clothify/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'api_service.dart';

class MeasurementsDBHelper {
  static MeasurementsDBHelper? _instance;

  static MeasurementsDBHelper get instance {
    _instance ??= MeasurementsDBHelper._();
    return _instance!;
  }

  MeasurementsDBHelper._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get database async => await _dbHelper.database;

  Future<void> createMeasurementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_measurements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        chest REAL,
        waist REAL,
        shoulder_width REAL,
        left_arm_length REAL,
        right_arm_length REAL,
        neck_circumference REAL,
        chest_inches REAL,
        waist_inches REAL,
        shoulder_width_inches REAL,
        left_arm_length_inches REAL,
        right_arm_length_inches REAL,
        neck_circumference_inches REAL,
        user_height_inches REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id)
      )
    ''');
  }

  Future<bool> saveMeasurements(
    int userId,
    Map<String, double> measurements, {
    String unit = 'pixels',
  }) async {
    try {
      return await ApiService.updateMeasurements(userId, measurements, unit);
    } catch (e) {
      print('Error in saveMeasurements: $e');
      return _fallbackSaveMeasurements(userId, measurements, unit);
    }
  }

  Future<bool> _fallbackSaveMeasurements(
    int userId,
    Map<String, double> measurements,
    String unit,
  ) async {
    try {
      final db = await database;
      final existing = await db.query(
        'user_measurements',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final now = DateTime.now().toIso8601String();
      final data = {'user_id': userId, 'updated_at': now};

      final isPixels = unit == 'pixels';

      final keys = [
        'chest',
        'waist',
        'shoulder_width',
        'left_arm_length',
        'right_arm_length',
        'neck_circumference',
      ];

      for (var key in keys) {
        final dbKey = isPixels ? key : '${key}_inches';
        data[dbKey] = measurements[key]!;
      }

      if (existing.isEmpty) {
        final id = await db.insert('user_measurements', data);
        return id > 0;
      } else {
        final count = await db.update(
          'user_measurements',
          data,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        return count > 0;
      }
    } catch (e) {
      print('Error in _fallbackSaveMeasurements: $e');
      return false;
    }
  }

  Future<bool> deleteMeasurements(int userId) async {
    try {
      if (await ApiService.deleteMeasurements(userId)) return true;

      final db = await database;
      final count = await db.delete(
        'user_measurements',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return count > 0;
    } catch (e) {
      print('Error deleting measurements: $e');
      return false;
    }
  }

  Future<Map<String, double>?> getMeasurements(
    int userId, {
    String unit = 'pixels',
  }) async {
    try {
      final apiMeasurements = await ApiService.getUserMeasurements(
        userId,
        unit: unit,
      );
      if (apiMeasurements != null) {
        return Map<String, double>.from(apiMeasurements);
      }

      final db = await database;

      final fields = [
        'chest',
        'waist',
        'shoulder_width',
        'left_arm_length',
        'right_arm_length',
        'neck_circumference',
      ];

      final columns =
          unit == 'inches'
              ? fields.map((f) => '${f}_inches as $f').toList()
              : fields;

      final results = await db.query(
        'user_measurements',
        columns: columns,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) return null;

      final data = results.first;
      final measurements = <String, double>{};

      data.forEach((key, value) {
        measurements[key] =
            value != null
                ? (value is double ? value : (value as num).toDouble())
                : 0.0;
      });

      return measurements;
    } catch (e) {
      print('Error getting measurements: $e');
      return null;
    }
  }

  Future<bool> hasMeasurements(int userId) async {
    try {
      if (await ApiService.hasMeasurements(userId)) return true;

      final db = await database;
      final results = await db.query(
        'user_measurements',
        columns: ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return results.isNotEmpty;
    } catch (e) {
      print('Error checking measurements: $e');
      return false;
    }
  }
}
