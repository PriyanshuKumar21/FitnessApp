import 'dart:async';
import 'dart:isolate';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// A thread pool for intensive calculations like calorie estimation and BMI calculation
class CalculationThreadPool {
  static final CalculationThreadPool _instance = CalculationThreadPool._internal();
  factory CalculationThreadPool() => _instance;
  
  // Thread pool configuration
  final int _maxWorkers = 4; // Maximum number of worker threads
  final List<_Worker> _workers = [];
  final Queue<_Task> _taskQueue = Queue<_Task>();
  bool _isInitialized = false;
  
  CalculationThreadPool._internal();
  
  /// Initialize the thread pool
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('Initializing calculation thread pool with $_maxWorkers workers');
    
    // Create worker threads
    for (int i = 0; i < _maxWorkers; i++) {
      final worker = _Worker(i);
      await worker.initialize();
      _workers.add(worker);
    }
    
    _isInitialized = true;
  }
  
  /// Submit a calculation task to the thread pool
  Future<T> submitTask<T>(String taskType, Map<String, dynamic> params) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Create a completer for the task result
    final completer = Completer<T>();
    
    // Create a task
    final task = _Task<T>(
      taskType: taskType,
      params: params,
      completer: completer,
    );
    
    // Find an available worker or queue the task
    final availableWorker = _findAvailableWorker();
    if (availableWorker != null) {
      _assignTaskToWorker(task, availableWorker);
    } else {
      _taskQueue.add(task);
    }
    
    return completer.future;
  }
  
  /// Find an available worker
  _Worker? _findAvailableWorker() {
    for (final worker in _workers) {
      if (!worker.isBusy) {
        return worker;
      }
    }
    return null;
  }
  
  /// Assign a task to a worker
  void _assignTaskToWorker(_Task task, _Worker worker) {
    worker.executeTask(task);
    
    // When the worker is done, assign it a new task if there are any in the queue
    worker.onTaskComplete = () {
      if (_taskQueue.isNotEmpty) {
        final nextTask = _taskQueue.removeFirst();
        _assignTaskToWorker(nextTask, worker);
      }
    };
  }
  
  /// Calculate BMI
  Future<double> calculateBMI({required double weightKg, required double heightCm}) async {
    return await submitTask<double>('calculate_bmi', {
      'weight_kg': weightKg,
      'height_cm': heightCm,
    });
  }
  
  /// Calculate calories burned during a workout
  Future<double> calculateCaloriesBurned({
    required double weightKg,
    required String activityType,
    required int durationMinutes,
    required int intensity, // 1-10
  }) async {
    return await submitTask<double>('calculate_calories', {
      'weight_kg': weightKg,
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
    });
  }
  
  /// Calculate daily calorie needs
  Future<Map<String, double>> calculateDailyCalorieNeeds({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required String gender,
    required String activityLevel, // sedentary, light, moderate, active, very_active
    required String goal, // 'maintain', 'gain', or 'lose'
  }) async {
    return await submitTask<Map<String, double>>('calculate_daily_calories', {
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age_years': ageYears,
      'gender': gender,
      'activity_level': activityLevel,
      'goal': goal,
    });
  }
  
  /// Shutdown the thread pool
  Future<void> shutdown() async {
    for (final worker in _workers) {
      await worker.dispose();
    }
    _workers.clear();
    _taskQueue.clear();
    _isInitialized = false;
  }
}

/// Worker class representing a thread in the pool
class _Worker {
  final int id;
  bool isBusy = false;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  Function? onTaskComplete;
  
  _Worker(this.id);
  
  /// Initialize the worker
  Future<void> initialize() async {
    _receivePort = ReceivePort();
    
    // Create the isolate
    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      _receivePort!.sendPort,
    );
    
    // Get the send port from the isolate
    _sendPort = await _receivePort!.first as SendPort;
    
    // Listen for messages from the isolate
    _receivePort!.listen(_handleMessage);
  }
  
  /// Execute a task on this worker
  void executeTask(_Task task) {
    isBusy = true;
    
    // Send the task to the isolate
    _sendPort!.send({
      'task_type': task.taskType,
      'params': task.params,
      'task_id': task.hashCode,
    });
    
    // Store the task for completion
    _currentTask = task;
  }
  
  // Current task being executed
  _Task? _currentTask;
  
  /// Handle messages from the isolate
  void _handleMessage(dynamic message) {
    if (message is Map<String, dynamic> && message.containsKey('result')) {
      // Task completed
      final taskId = message['task_id'];
      final result = message['result'];
      
      if (_currentTask != null && _currentTask.hashCode == taskId) {
        _currentTask!.completer.complete(result);
        _currentTask = null;
        isBusy = false;
        
        // Notify that the task is complete
        onTaskComplete?.call();
      }
    }
  }
  
  /// Dispose of the worker
  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _receivePort = null;
    _sendPort = null;
  }
  
  /// Entry point for the worker isolate
  static void _workerEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    
    // Send the send port back to the main isolate
    sendPort.send(receivePort.sendPort);
    
    // Listen for tasks
    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        final taskType = message['task_type'] as String;
        final params = message['params'] as Map<String, dynamic>;
        final taskId = message['task_id'] as int;
        
        // Process the task
        final result = _processTask(taskType, params);
        
        // Send the result back
        sendPort.send({
          'result': result,
          'task_id': taskId,
        });
      }
    });
  }
  
  /// Process a task
  static dynamic _processTask(String taskType, Map<String, dynamic> params) {
    switch (taskType) {
      case 'calculate_bmi':
        return _calculateBMI(params);
      case 'calculate_calories':
        return _calculateCaloriesBurned(params);
      case 'calculate_daily_calories':
        return _calculateDailyCalorieNeeds(params);
      default:
        throw Exception('Unknown task type: $taskType');
    }
  }
  
  /// Calculate BMI
  static double _calculateBMI(Map<String, dynamic> params) {
    final weightKg = params['weight_kg'] as double;
    final heightCm = params['height_cm'] as double;
    
    // Convert height to meters
    final heightM = heightCm / 100;
    
    // Calculate BMI using the standard formula: BMI = weight(kg) / (height(m) * height(m))
    return weightKg / (heightM * heightM);
  }
  
  /// Calculate calories burned during a workout
  static double _calculateCaloriesBurned(Map<String, dynamic> params) {
    final weightKg = params['weight_kg'] as double;
    final activityType = params['activity_type'] as String;
    final durationMinutes = params['duration_minutes'] as int;
    final intensity = params['intensity'] as int;
    
    // MET values for different activities
    final Map<String, double> metValues = {
      'walking': 3.5,
      'running': 8.0,
      'cycling': 7.0,
      'swimming': 6.0,
      'yoga': 2.5,
      'weight_training': 3.5,
      'hiit': 8.0,
      'other': 4.0,
    };
    
    // Get the MET value for the activity
    final met = metValues[activityType] ?? metValues['other']!;
    
    // Adjust MET based on intensity (1-10)
    final adjustedMet = met * (0.8 + (intensity * 0.04));
    
    // Calculate calories burned
    // Formula: calories = MET * weight in kg * duration in hours
    final durationHours = durationMinutes / 60;
    final caloriesBurned = adjustedMet * weightKg * durationHours;
    
    return caloriesBurned;
  }
  
  /// Calculate daily calorie needs
  static Map<String, double> _calculateDailyCalorieNeeds(Map<String, dynamic> params) {
    final weightKg = params['weight_kg'] as double;
    final heightCm = params['height_cm'] as double;
    final ageYears = params['age_years'] as int;
    final gender = params['gender'] as String;
    final activityLevel = params['activity_level'] as String;
    final goal = params['goal'] as String? ?? 'maintain'; // 'maintain', 'gain', or 'lose'
    
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * ageYears + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161;
    }
    
    // Activity multipliers
    final Map<String, double> activityMultipliers = {
      'sedentary': 1.2,      // Little or no exercise
      'light': 1.375,        // Light exercise 1-3 days/week
      'moderate': 1.55,      // Moderate exercise 3-5 days/week
      'active': 1.725,       // Heavy exercise 6-7 days/week
      'very_active': 1.9,    // Very heavy exercise, physical job or training twice a day
    };
    
    final multiplier = activityMultipliers[activityLevel] ?? activityMultipliers['moderate']!;
    
    // Calculate total daily energy expenditure (TDEE)
    final tdee = bmr * multiplier;
    
    // Adjust calories based on goal
    double adjustedTdee = tdee;
    if (goal == 'gain') {
      adjustedTdee = tdee + 300; // Caloric surplus for weight gain
    } else if (goal == 'lose') {
      adjustedTdee = tdee - 300; // Caloric deficit for weight loss
    }
    
    // Calculate macronutrient needs
    // Protein: 1.6g per kg of body weight
    final proteinG = weightKg * 1.6;
    final proteinCalories = proteinG * 4; // 4 calories per gram of protein
    
    // Fat: 25% of total calories
    final fatCalories = adjustedTdee * 0.25;
    final fatG = fatCalories / 9; // 9 calories per gram of fat
    
    // Carbs: remaining calories
    final carbCalories = adjustedTdee - proteinCalories - fatCalories;
    final carbG = carbCalories / 4; // 4 calories per gram of carbs
    
    return {
      'tdee': tdee,
      'adjusted_tdee': adjustedTdee,
      'bmr': bmr,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbs_g': carbG,
    };
  }
}

/// Task class representing a calculation task
class _Task<T> {
  final String taskType;
  final Map<String, dynamic> params;
  final Completer<T> completer;
  
  _Task({
    required this.taskType,
    required this.params,
    required this.completer,
  });
} 