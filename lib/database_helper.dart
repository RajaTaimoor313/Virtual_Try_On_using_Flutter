import 'dart:async';
import 'package:clothify/Measurements/measurements_database_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static DatabaseHelper? _instance;

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'clothify.db');

    var db = await openDatabase(
      path,
      version: 6,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );

    return db;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('PRAGMA foreign_keys = OFF;');

    if (oldVersion < 2) {
      final measurementsDb = MeasurementsDBHelper.instance;
      await measurementsDb.createMeasurementsTable(db);
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE clothing_items ADD COLUMN model_path TEXT');

      for (int i = 1; i <= 5; i++) {
        await db.update(
          'clothing_items',
          {'model_path': 'assets/Jackets/jacket$i.glb'},
          where: 'name = ? AND category = ?',
          whereArgs: ['Jacket $i', 'Jackets'],
        );
      }
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_clicks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          click_count INTEGER NOT NULL DEFAULT 1,
          last_clicked TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (item_id) REFERENCES clothing_items (id) ON DELETE CASCADE,
          UNIQUE(user_id, item_id)
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_item_clicks_user_item 
        ON item_clicks(user_id, item_id)
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS favorites');

      await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          added_at TEXT NOT NULL,
          UNIQUE(user_id, item_id)
        )
      ''');
    }

    if (oldVersion < 6) {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorites'",
      );

      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            item_id INTEGER NOT NULL,
            added_at TEXT NOT NULL,
            UNIQUE(user_id, item_id)
          )
        ''');
      } else {
        final columns = await db.rawQuery("PRAGMA table_info(favorites)");
        bool hasItemId = false;

        for (var col in columns) {
          if (col['name'] == 'item_id') {
            hasItemId = true;
            break;
          }
        }

        if (!hasItemId) {
          await db.execute('ALTER TABLE favorites RENAME TO favorites_old');

          await db.execute('''
            CREATE TABLE favorites(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              item_id INTEGER NOT NULL,
              added_at TEXT NOT NULL,
              UNIQUE(user_id, item_id)
            )
          ''');

          try {
            await db.execute('''
              INSERT INTO favorites (user_id, item_id, added_at)
              SELECT user_id, item_id, added_at FROM favorites_old
            ''');
          } catch (e) {
            print('Error migrating favorites data: $e');
          }

          await db.execute('DROP TABLE IF EXISTS favorites_old');
        }
      }
    }

    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = OFF;');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE clothing_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT NOT NULL,
        model_path TEXT
      )
    ''');

    final measurementsDb = MeasurementsDBHelper.instance;
    await measurementsDb.createMeasurementsTable(db);

    await db.execute('''
      CREATE TABLE item_clicks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        click_count INTEGER NOT NULL DEFAULT 1,
        last_clicked TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES clothing_items (id) ON DELETE CASCADE,
        UNIQUE(user_id, item_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_item_clicks_user_item 
      ON item_clicks(user_id, item_id)
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        added_at TEXT NOT NULL,
        UNIQUE(user_id, item_id)
      )
    ''');

    await _insertInitialClothingItems(db);

    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _insertInitialClothingItems(Database db) async {
    await db.transaction((txn) async {
      for (int i = 1; i <= 5; i++) {
        await txn.insert('clothing_items', {
          'name': 'T-Shirt $i',
          'category': 'T-Shirts',
          'image_path': 'assets/T-Shirts/t-shirt$i.png',
          'model_path': 'assets/T-Shirts/t-shirt$i.glb',
        });
      }

      for (int i = 1; i <= 5; i++) {
        await txn.insert('clothing_items', {
          'name': 'Shirt $i',
          'category': 'Shirts',
          'image_path': 'assets/Shirts/shirt$i.png',
          'model_path': 'assets/Shirts/shirt$i.glb',
        });
      }

      for (int i = 1; i <= 5; i++) {
        await txn.insert('clothing_items', {
          'name': 'Jacket $i',
          'category': 'Jackets',
          'image_path': 'assets/Jackets/jacket$i.png',
          'model_path': 'assets/Jackets/jacket$i.glb',
        });
      }
    });
  }

  Future<bool> addToFavorites(int userId, int itemId) async {
    try {
      final db = await database;

      await _ensureFavoritesTable(db);

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM favorites WHERE user_id = ? AND item_id = ?',
          [userId, itemId],
        ),
      );

      if (count != null && count > 0) {
        return true;
      }

      final result = await db.insert('favorites', {
        'user_id': userId,
        'item_id': itemId,
        'added_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Add favorite result: $result');
      return result > 0;
    } catch (e) {
      print('Error adding favorite: $e');
      print(StackTrace.current);
      return false;
    }
  }

  Future<bool> removeFromFavorites(int userId, int itemId) async {
    try {
      final db = await database;

      await _ensureFavoritesTable(db);

      final result = await db.delete(
        'favorites',
        where: 'user_id = ? AND item_id = ?',
        whereArgs: [userId, itemId],
      );

      print('Remove favorite result: $result');
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      print(StackTrace.current);
      return false;
    }
  }

  Future<bool> isFavorite(int userId, int itemId) async {
    try {
      final db = await database;

      await _ensureFavoritesTable(db);

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM favorites WHERE user_id = ? AND item_id = ?',
          [userId, itemId],
        ),
      );

      return count != null && count > 0;
    } catch (e) {
      print('Error checking favorite: $e');
      print(StackTrace.current);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
    try {
      final db = await database;

      await _ensureFavoritesTable(db);

      final results = await db.rawQuery(
        '''
        SELECT c.* 
        FROM clothing_items c
        INNER JOIN favorites f ON c.id = f.item_id
        WHERE f.user_id = ?
        ORDER BY f.added_at DESC
      ''',
        [userId],
      );

      return results;
    } catch (e) {
      print('Error getting user favorites: $e');
      print(StackTrace.current);
      return [];
    }
  }

  Future<void> _ensureFavoritesTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorites'",
      );

      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            item_id INTEGER NOT NULL,
            added_at TEXT NOT NULL,
            UNIQUE(user_id, item_id)
          )
        ''');
        print('Created new favorites table');
        return;
      }

      final columns = await db.rawQuery("PRAGMA table_info(favorites)");

      bool hasId = false;
      bool hasUserId = false;
      bool hasItemId = false;
      bool hasAddedAt = false;

      for (var col in columns) {
        final name = col['name'];
        if (name == 'id') hasId = true;
        if (name == 'user_id') hasUserId = true;
        if (name == 'item_id') hasItemId = true;
        if (name == 'added_at') hasAddedAt = true;
      }

      if (hasId && hasUserId && hasItemId && hasAddedAt) {
        return;
      }

      print('Favorites table missing columns. Recreating...');

      List<Map<String, dynamic>> existingData = [];
      try {
        existingData = await db.query('favorites');
      } catch (e) {
        print('Could not retrieve existing favorites data: $e');
      }

      await db.execute('DROP TABLE IF EXISTS favorites');

      await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          added_at TEXT NOT NULL,
          UNIQUE(user_id, item_id)
        )
      ''');

      if (existingData.isNotEmpty) {
        try {
          for (var row in existingData) {
            if (row.containsKey('user_id') && row.containsKey('item_id')) {
              await db.insert('favorites', {
                'user_id': row['user_id'],
                'item_id': row['item_id'],
                'added_at': row['added_at'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
          print('Restored ${existingData.length} favorites');
        } catch (e) {
          print('Error restoring favorites data: $e');
        }
      }
    } catch (e) {
      print('Error ensuring favorites table: $e');
      print(StackTrace.current);

      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          added_at TEXT NOT NULL,
          UNIQUE(user_id, item_id)
        )
      ''');
    }
  }

  Future<void> verifyFavoritesTable() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print("Database tables: $tables");

      final favoritesStructure = await db.rawQuery(
        "PRAGMA table_info(favorites)",
      );
      print("Favorites table structure: $favoritesStructure");

      final favCount = await db.rawQuery("SELECT COUNT(*) FROM favorites");
      print("Favorites count: $favCount");
    } catch (e) {
      print("Error checking favorites table: $e");
      print(StackTrace.current);
    }
  }

  Future<void> recordItemClick(int userId, int itemId) async {
    final db = await database;

    try {
      final results = await db.query(
        'item_clicks',
        where: 'user_id = ? AND item_id = ?',
        whereArgs: [userId, itemId],
      );

      final now = DateTime.now().toIso8601String();

      if (results.isEmpty) {
        await db.insert('item_clicks', {
          'user_id': userId,
          'item_id': itemId,
          'click_count': 1,
          'last_clicked': now,
        });
      } else {
        await db.update(
          'item_clicks',
          {
            'click_count': (results.first['click_count'] as int) + 1,
            'last_clicked': now,
          },
          where: 'user_id = ? AND item_id = ?',
          whereArgs: [userId, itemId],
        );
      }
    } catch (e) {
      print('Error recording item click: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMostPopularItems(int limit) async {
    final db = await database;

    try {
      return await db.rawQuery(
        '''
        SELECT c.*, SUM(ic.click_count) as total_clicks 
        FROM clothing_items c
        INNER JOIN item_clicks ic ON c.id = ic.item_id
        GROUP BY c.id
        ORDER BY total_clicks DESC
        LIMIT ?
      ''',
        [limit],
      );
    } catch (e) {
      print('Error getting popular items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserRecommendedItems(
    int userId,
    int limit,
  ) async {
    final db = await database;

    try {
      return await db.rawQuery(
        '''
        SELECT c.*, ic.click_count 
        FROM clothing_items c
        INNER JOIN item_clicks ic ON c.id = ic.item_id
        WHERE ic.user_id = ?
        ORDER BY ic.click_count DESC, ic.last_clicked DESC
        LIMIT ?
      ''',
        [userId, limit],
      );
    } catch (e) {
      print('Error getting user recommended items: $e');
      return [];
    }
  }

  Future<bool> areForeignKeysEnabled() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA foreign_keys;');
    final isEnabled = result.isNotEmpty && result.first.values.first == 1;
    print('Foreign keys enabled: $isEnabled');
    return isEnabled;
  }

  Future<List<Map<String, dynamic>>> getClothingItemsByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'clothing_items',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<List<Map<String, dynamic>>> getAllClothingItems() async {
    final db = await database;
    return await db.query('clothing_items');
  }

  Future<List<Map<String, dynamic>>> getPopularClothingItems(int limit) async {
    final db = await database;
    return await db.query('clothing_items', limit: limit);
  }

  Future<Map<String, dynamic>?> getClothingItemById(int id) async {
    final db = await database;
    final results = await db.query(
      'clothing_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        return false;
      }

      final db = await database;
      final id = await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'created_at': DateTime.now().toIso8601String(),
      });

      return id > 0;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return false;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<bool> updatePassword(String email, String newPassword) async {
    final db = await database;
    final count = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );

    return count > 0;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
