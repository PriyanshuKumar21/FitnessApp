import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/custom_workout_model.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class CustomWorkoutService extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CustomWorkout> _customWorkouts = [];
  bool _isLoading = false;
  String? _error;
  
  // Constructor
  CustomWorkoutService(this._authService) {
    _initializeService();
  }
  
  // Getters
  List<CustomWorkout> get customWorkouts => _customWorkouts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize service
  Future<void> _initializeService() async {
    await loadCustomWorkouts();
  }
  
  // Load custom workouts for current user
  Future<void> loadCustomWorkouts() async {
    if (_authService.currentUser == null) {
      _customWorkouts = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = _authService.currentUser!.id;
      _customWorkouts = await _dbHelper.getCustomWorkoutsForUser(userId);
      _error = null;
    } catch (e) {
      _error = "Failed to load custom workouts: ${e.toString()}";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new custom workout
  Future<bool> addCustomWorkout({
    required String name,
    required String type,
    required String description,
    required String duration,
    required int calories,
    required String difficulty,
    required Color color,
    required IconData icon,
    required List<Map<String, dynamic>> exercises,
  }) async {
    if (_authService.currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = _authService.currentUser!.id;
      
      final workout = CustomWorkout(
        userId: userId,
        name: name,
        type: type,
        description: description,
        duration: duration,
        calories: calories,
        difficulty: difficulty,
        color: color,
        icon: icon,
        exercises: exercises,
      );
      
      final id = await _dbHelper.insertCustomWorkout(workout);
      
      if (id > 0) {
        // Reload custom workouts
        await loadCustomWorkouts();
        return true;
      } else {
        _error = "Failed to add custom workout";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to add custom workout: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a custom workout
  Future<bool> deleteCustomWorkout(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _dbHelper.deleteCustomWorkout(id);
      
      if (result > 0) {
        // Reload custom workouts
        await loadCustomWorkouts();
        return true;
      } else {
        _error = "Failed to delete custom workout";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to delete custom workout: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 