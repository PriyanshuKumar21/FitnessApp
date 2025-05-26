import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fitness_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration INTEGER NOT NULL,
        steps INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_steps INTEGER NOT NULL,
        total_workout_time INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertWorkout(Map<String, dynamic> workout) async {
    Database db = await database;
    return await db.insert('workouts', workout);
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    Database db = await database;
    return await db.query('workouts', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getWorkoutsByDate(String date) async {
    Database db = await database;
    return await db.query(
      'workouts',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<int> updateDailyStats(Map<String, dynamic> stats) async {
    Database db = await database;
    return await db.insert(
      'daily_stats',
      stats,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDailyStats() async {
    Database db = await database;
    return await db.query('daily_stats', orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getDailyStatsByDate(String date) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [date],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> deleteWorkout(int id) async {
    Database db = await database;
    return await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    Database db = await database;
    await db.close();
  }
} 