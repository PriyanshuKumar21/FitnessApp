import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';
import '../models/custom_workout_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static Database? _database;
  
  // Database version - increment when schema changes
  final int _version = 6;
  
  // Database name
  final String _databaseName = 'fitness_app.db';
  
  DatabaseHelper._internal() {
    // Initialize FFI for Windows
    if (Platform.isWindows) {
      debugPrint('Initializing sqflite_ffi for Windows');
      sqfliteFfiInit();
    }
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, _databaseName);
    
    debugPrint('Initializing database at: $dbPath');
    
    return await openDatabase(
      dbPath,
      version: _version, // Increment database version for reminders table
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    debugPrint('Creating database tables...');
    
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        photo_url TEXT,
        registration_date INTEGER NOT NULL,
        is_verified INTEGER NOT NULL DEFAULT 0,
        gender TEXT DEFAULT 'male'
      )
    ''');
    
    // Create user_auth table
    await db.execute('''
      CREATE TABLE user_auth(
        user_id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create workout_history table
    await db.execute('''
      CREATE TABLE workout_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        workout_name TEXT NOT NULL,
        workout_type TEXT NOT NULL,
        duration INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create step_counts table
    await db.execute('''
      CREATE TABLE step_counts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create user_profile table
    await db.execute('''
      CREATE TABLE user_profile(
        user_id TEXT PRIMARY KEY,
        height INTEGER,
        weight INTEGER,
        age INTEGER,
        fitness_goal TEXT,
        daily_step_target INTEGER DEFAULT 10000,
        weekly_workout_target INTEGER DEFAULT 3,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create reminders table
    await db.execute('''
      CREATE TABLE reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        reminder_time INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        type TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create custom_workouts table
    await db.execute('''
      CREATE TABLE custom_workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        duration TEXT NOT NULL,
        calories INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        icon_font_package TEXT,
        exercises TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }
  
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    // Handle version 1 to 2 upgrade
    if (oldVersion < 2) {
      // Create user_auth table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_auth(
          user_id TEXT PRIMARY KEY,
          password_hash TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create user_profile table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile(
          user_id TEXT PRIMARY KEY,
          height INTEGER,
          weight INTEGER,
          age INTEGER,
          fitness_goal TEXT,
          last_updated INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }

    // Handle version 2 to 3 upgrade - fix column names 
    if (oldVersion < 3) {
      debugPrint('Upgrading from version 2 to 3 - fixing column names');
      
      // Check if the users table needs to be updated
      final userTableInfo = await db.rawQuery("PRAGMA table_info(users)");
      
      // Fix column names in users table if needed
      bool hasPhotoUrlColumn = false;
      bool hasRegistrationDateColumn = false;
      bool hasPasswordHashColumn = false;
      
      for (var column in userTableInfo) {
        final columnName = column['name'] as String;
        if (columnName == 'photoUrl') hasPhotoUrlColumn = true;
        if (columnName == 'registrationDate') hasRegistrationDateColumn = true;
        if (columnName == 'password_hash') hasPasswordHashColumn = true;
      }
      
      // Handle column name migrations
      if (hasPhotoUrlColumn || hasRegistrationDateColumn) {
        // Rename columns to snake_case
        debugPrint('Migrating column names to snake_case');
        
        try {
          // Create temporary table with correct schema
          await db.execute('''
            CREATE TABLE users_temp(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT UNIQUE NOT NULL,
              photo_url TEXT,
              registration_date INTEGER NOT NULL,
              is_verified INTEGER NOT NULL DEFAULT 0
            )
          ''');
          
          // Copy data, transforming as needed
          if (hasPhotoUrlColumn && hasRegistrationDateColumn) {
            await db.execute('''
              INSERT INTO users_temp(id, name, email, photo_url, registration_date, is_verified)
              SELECT id, name, email, photoUrl, 
                CASE 
                  WHEN registrationDate IS NULL THEN ${DateTime.now().millisecondsSinceEpoch} 
                  ELSE registrationDate 
                END, 
                is_verified FROM users
            ''');
          } else if (hasPhotoUrlColumn) {
            await db.execute('''
              INSERT INTO users_temp(id, name, email, photo_url, registration_date, is_verified)
              SELECT id, name, email, photoUrl, ${DateTime.now().millisecondsSinceEpoch}, is_verified FROM users
            ''');
          } else if (hasRegistrationDateColumn) {
            await db.execute('''
              INSERT INTO users_temp(id, name, email, photo_url, registration_date, is_verified)
              SELECT id, name, email, '', 
                CASE 
                  WHEN registrationDate IS NULL THEN ${DateTime.now().millisecondsSinceEpoch} 
                  ELSE registrationDate 
                END, 
                is_verified FROM users
            ''');
          }
          
          // Drop old table
          await db.execute('DROP TABLE users');
          
          // Rename new table to old name
          await db.execute('ALTER TABLE users_temp RENAME TO users');
          
          debugPrint('Successfully migrated users table schema');
        } catch (e) {
          debugPrint('Error migrating users table: $e');
        }
      }
      
      // Migrate passwords to user_auth table if needed
      if (hasPasswordHashColumn) {
        debugPrint('Migrating password_hash to user_auth table');
        
        try {
          // Get all users with password hashes
          final users = await db.query('users');
          
          // Insert each user's password hash into user_auth table
          for (var user in users) {
            final userId = user['id'] as String;
            final passwordHash = user['password_hash'] as String?;
            
            if (passwordHash != null) {
              await db.insert(
                'user_auth',
                {
                  'user_id': userId,
                  'password_hash': passwordHash,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          
          debugPrint('Successfully migrated password hashes to user_auth table');
        } catch (e) {
          debugPrint('Error migrating password hashes: $e');
        }
      }

      // Fix date and steps columns in step_counts table
      try {
        final stepCountsTableInfo = await db.rawQuery("PRAGMA table_info(step_counts)");
        bool hasCountColumn = false;

        for (var column in stepCountsTableInfo) {
          final columnName = column['name'] as String;
          if (columnName == 'count') hasCountColumn = true;
        }

        if (hasCountColumn) {
          // Create temporary table with correct schema
          await db.execute('''
            CREATE TABLE step_counts_temp(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              date TEXT NOT NULL,
              steps INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          
          // Copy data, transforming as needed
          await db.execute('''
            INSERT INTO step_counts_temp(id, user_id, date, steps)
            SELECT id, user_id, date, count FROM step_counts
          ''');
          
          // Drop old table
          await db.execute('DROP TABLE step_counts');
          
          // Rename new table to old name
          await db.execute('ALTER TABLE step_counts_temp RENAME TO step_counts');
          
          debugPrint('Successfully migrated step_counts table schema');
        }
      } catch (e) {
        debugPrint('Error migrating step_counts table: $e');
      }
    }

    // Handle version 3 to 4 upgrade - add reminders table and gender field
    if (oldVersion < 4) {
      // Create reminders table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          reminder_time INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          type TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      debugPrint('Upgrading from version 3 to 4 - adding gender field');
      try {
        await db.execute('ALTER TABLE users ADD COLUMN gender TEXT DEFAULT "male"');
      } catch (e) {
        debugPrint('Error adding gender column: $e');
        // Column might already exist, continue
      }
    }

    // Handle version 4 to 5 upgrade - add step and workout targets
    if (oldVersion < 5) {
      debugPrint('Upgrading from version 4 to 5 - adding step and workout targets');
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN daily_step_target INTEGER DEFAULT 10000');
        await db.execute('ALTER TABLE user_profile ADD COLUMN weekly_workout_target INTEGER DEFAULT 3');
      } catch (e) {
        debugPrint('Error adding target columns: $e');
        // Columns might already exist, continue
      }
    }
    
    // Handle version 5 to 6 upgrade - ensure gender column exists
    if (oldVersion < 6) {
      debugPrint('Upgrading from version 5 to 6 - ensuring gender column exists');
      try {
        // Check if gender column exists
        final userTableInfo = await db.rawQuery("PRAGMA table_info(users)");
        bool hasGenderColumn = false;
        
        for (var column in userTableInfo) {
          final columnName = column['name'] as String;
          if (columnName == 'gender') hasGenderColumn = true;
        }
        
        if (!hasGenderColumn) {
          await db.execute('ALTER TABLE users ADD COLUMN gender TEXT DEFAULT "male"');
          debugPrint('Added gender column to users table');
        } else {
          debugPrint('Gender column already exists');
        }
      } catch (e) {
        debugPrint('Error ensuring gender column: $e');
      }
    }
  }
  
  // User operations
  Future<int> insertUser(User user, String passwordHash) async {
    debugPrint('Inserting user: ${user.name}, Email: ${user.email}');
    final db = await database;
    
    try {
      // First, insert into users table with correct column names
      final userData = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'photo_url': user.photoUrl,
        'registration_date': user.registrationDate.millisecondsSinceEpoch,
        'is_verified': user.isVerified ? 1 : 0,
        'gender': user.gender,
      };
      
      debugPrint('User data map to insert: $userData');
      
      int result = await db.insert(
        'users',
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Then, insert password hash into user_auth table
      await db.insert(
        'user_auth',
        {
          'user_id': user.id,
          'password_hash': passwordHash,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('User inserted successfully with result: $result');
      return result;
    } catch (e) {
      debugPrint('Error inserting user: $e');
      rethrow;
    }
  }
  
  Future<User?> getUserById(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return User.fromMap(maps.first);
  }
  
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isEmpty) return null;
    
    return User.fromMap(maps.first);
  }
  
  Future<String?> getPasswordHashByEmail(String email) async {
    final db = await database;
    
    // First, get the user_id from the users table
    final List<Map<String, dynamic>> userMaps = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (userMaps.isEmpty) return null;
    
    String userId = userMaps.first['id'] as String;
    
    // Then, get the password hash from the user_auth table
    final List<Map<String, dynamic>> authMaps = await db.query(
      'user_auth',
      columns: ['password_hash'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (authMaps.isEmpty) return null;
    
    return authMaps.first['password_hash'] as String;
  }
  
  Future<int> updateUser(User user) async {
    final db = await database;
    
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  Future<int> deleteUser(String id) async {
    final db = await database;
    
    // Delete related records first
    await db.delete(
      'workout_history',
      where: 'user_id = ?',
      whereArgs: [id],
    );
    
    await db.delete(
      'step_counts',
      where: 'user_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the user
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Workout history operations
  Future<int> insertWorkoutHistory(String userId, String workoutName, DateTime date, int durationMinutes, int caloriesBurned) async {
    final db = await database;
    
    return await db.insert(
      'workout_history',
      {
        'user_id': userId,
        'workout_name': workoutName,
        'date': date.toIso8601String(),
        'duration': durationMinutes,
        'calories_burned': caloriesBurned,
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> getWorkoutHistoryForUser(String userId) async {
    final db = await database;
    
    return await db.query(
      'workout_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }
  
  // Step count operations
  Future<int> insertStepCount(String userId, DateTime date, int steps) async {
    final db = await database;
    
    // Check if there's already an entry for this date
    final existingRecord = await db.query(
      'step_counts',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date.toIso8601String().split('T')[0]], // Just the date part
    );
    
    if (existingRecord.isNotEmpty) {
      // Update existing record
      return await db.update(
        'step_counts',
        {'steps': steps},
        where: 'id = ?',
        whereArgs: [existingRecord.first['id']],
      );
    } else {
      // Insert new record
      return await db.insert(
        'step_counts',
        {
          'user_id': userId,
          'date': date.toIso8601String().split('T')[0], // Just the date part
          'steps': steps,
        },
      );
    }
  }
  
  Future<List<Map<String, dynamic>>> getStepCountsForUser(String userId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }
    
    return await db.query(
      'step_counts',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date ASC',
    );
  }
  
  // Get total steps for a date range
  Future<int> getTotalStepsForDateRange(String userId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT SUM(steps) as total_steps
      FROM step_counts
      WHERE user_id = ? AND date >= ? AND date <= ?
    ''', [
      userId,
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ]);
    
    return (result.first['total_steps'] as int?) ?? 0;
  }
  
  // User profile operations
  Future<int> saveUserProfile({
    required String userId,
    required int height,
    required int weight,
    required int age,
    required String fitnessGoal,
    int? dailyStepTarget,
    int? weeklyWorkoutTarget,
  }) async {
    final db = await database;
    
    return await db.insert(
      'user_profile',
      {
        'user_id': userId,
        'height': height,
        'weight': weight,
        'age': age,
        'fitness_goal': fitnessGoal,
        if (dailyStepTarget != null) 'daily_step_target': dailyStepTarget,
        if (weeklyWorkoutTarget != null) 'weekly_workout_target': weeklyWorkoutTarget,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (maps.isEmpty) return null;
    
    return maps.first;
  }
  
  // Reminder operations
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    
    return await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Reminder>> getRemindersForUser(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'reminder_time ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }
  
  Future<Reminder?> getReminderById(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return Reminder.fromMap(maps.first);
  }
  
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }
  
  Future<int> toggleReminderActive(int id, bool isActive) async {
    final db = await database;
    
    return await db.update(
      'reminders',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> deleteReminder(int id) async {
    final db = await database;
    
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Custom Workout operations
  Future<int> insertCustomWorkout(CustomWorkout workout) async {
    final db = await database;
    
    return await db.insert(
      'custom_workouts',
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<CustomWorkout>> getCustomWorkoutsForUser(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_workouts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return CustomWorkout.fromMap(maps[i]);
    });
  }
  
  Future<CustomWorkout?> getCustomWorkoutById(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return CustomWorkout.fromMap(maps.first);
  }
  
  Future<int> updateCustomWorkout(CustomWorkout workout) async {
    final db = await database;
    
    return await db.update(
      'custom_workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }
  
  Future<int> deleteCustomWorkout(int id) async {
    final db = await database;
    
    return await db.delete(
      'custom_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
  
  // Delete database file - useful for troubleshooting
  Future<void> deleteDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, _databaseName);
    
    debugPrint('Deleting database at: $dbPath');
    
    try {
      await File(dbPath).delete();
      _database = null;
      debugPrint('Database deleted successfully');
    } catch (e) {
      debugPrint('Error deleting database: $e');
    }
  }
} 