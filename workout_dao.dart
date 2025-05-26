import '../models/workout_model.dart';
import 'db_helper.dart';

class WorkoutDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertWorkout(Workout workout) async {
    return await _dbHelper.insertWorkout(workout.toMap());
  }

  Future<List<Workout>> getWorkouts() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getWorkouts();
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  Future<List<Workout>> getWorkoutsByDate(String date) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getWorkoutsByDate(date);
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  Future<int> updateDailyStats(DailyStats stats) async {
    return await _dbHelper.updateDailyStats(stats.toMap());
  }

  Future<List<DailyStats>> getDailyStats() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getDailyStats();
    return List.generate(maps.length, (i) => DailyStats.fromMap(maps[i]));
  }

  Future<DailyStats?> getDailyStatsByDate(String date) async {
    final Map<String, dynamic>? map = await _dbHelper.getDailyStatsByDate(date);
    return map != null ? DailyStats.fromMap(map) : null;
  }

  Future<int> deleteWorkout(int id) async {
    return await _dbHelper.deleteWorkout(id);
  }

  Future<void> saveWorkoutSession({
    required String date,
    required int duration,
    required int steps,
    required String type,
  }) async {
    // Save workout
    final workout = Workout(
      date: date,
      duration: duration,
      steps: steps,
      type: type,
    );
    await insertWorkout(workout);

    // Update daily stats
    final existingStats = await getDailyStatsByDate(date);
    if (existingStats != null) {
      await updateDailyStats(
        existingStats.copyWith(
          totalSteps: existingStats.totalSteps + steps,
          totalWorkoutTime: existingStats.totalWorkoutTime + duration,
        ),
      );
    } else {
      await updateDailyStats(
        DailyStats(
          date: date,
          totalSteps: steps,
          totalWorkoutTime: duration,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final stats = await getDailyStats();
    if (stats.isEmpty) {
      return {
        'totalSteps': 0,
        'totalWorkoutTime': 0,
        'averageSteps': 0,
        'averageWorkoutTime': 0,
      };
    }

    int totalSteps = 0;
    int totalWorkoutTime = 0;

    for (var stat in stats) {
      totalSteps += stat.totalSteps;
      totalWorkoutTime += stat.totalWorkoutTime;
    }

    return {
      'totalSteps': totalSteps,
      'totalWorkoutTime': totalWorkoutTime,
      'averageSteps': totalSteps ~/ stats.length,
      'averageWorkoutTime': totalWorkoutTime ~/ stats.length,
    };
  }
} 