import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'background_step_service.dart';
import 'sensor_resource_manager.dart';
import 'calculation_thread_pool.dart';

class StepCounterService extends ChangeNotifier {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  
  // Step counting
  int _steps = 0;
  int _stepsTarget = 10000;
  DateTime _lastReset = DateTime.now();
  bool _isStepCounting = false;
  
  // Add these properties
  double _caloriesBurned = 0.0;
  double _distanceCovered = 0.0; // in kilometers
  
  // Subscriptions
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  
  // Services
  final BackgroundStepService _backgroundService = BackgroundStepService();
  final SensorResourceManager _sensorManager = SensorResourceManager();
  final CalculationThreadPool _calculationPool = CalculationThreadPool();
  
  // Service ID for resource manager
  final String _serviceId = 'step_counter_service_${DateTime.now().millisecondsSinceEpoch}';
  
  StepCounterService._internal() {
    _initializeServices();
  }
  
  /// Initialize the step counter service and its dependencies
  Future<void> _initializeServices() async {
    // Initialize the calculation thread pool
    await _calculationPool.initialize();
    
    // Initialize the sensor resource manager
    _sensorManager.initialize();
    
    // Load saved steps
    await _loadSavedSteps();
  }
  
  /// Get the current step count
  int get steps => _steps;
  
  /// Get the step target
  int get stepsTarget => _stepsTarget;
  
  /// Get calories burned
  double get caloriesBurned => _caloriesBurned;
  
  /// Get distance covered in kilometers
  double get distanceCovered => _distanceCovered;
  
  /// Set the step target
  set stepsTarget(int target) {
    _stepsTarget = target;
    _saveStepsTarget();
    notifyListeners();
  }
  
  /// Check if step counting is active
  bool get isStepCounting => _isStepCounting;
  
  /// Start counting steps
  Future<void> startCounting() async {
    if (_isStepCounting) return;
    
    debugPrint('Starting step counting');
    
    // Start the background service for continuous counting
    await _backgroundService.initialize();
    
    // Request the accelerometer resource for step detection
    try {
      final accelerometerStream = _sensorManager.requestResource<UserAccelerometerEvent>(
        'userAccelerometer',
        _serviceId,
        priority: ResourcePriority.high,
      );
      
      _accelerometerSubscription = accelerometerStream.listen(_processAccelerometerEvent);
      
      _isStepCounting = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting step counter: $e');
    }
  }
  
  /// Stop counting steps
  Future<void> stopCounting() async {
    if (!_isStepCounting) return;
    
    debugPrint('Stopping step counting');
    
    // Cancel the accelerometer subscription
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    
    // Release the accelerometer resource
    _sensorManager.releaseResource('userAccelerometer', _serviceId);
    
    // Stop the background service
    await _backgroundService.stop();
    
    // Save the current step count
    await _saveSteps();
    
    _isStepCounting = false;
    notifyListeners();
  }
  
  /// Process accelerometer events for step detection
  void _processAccelerometerEvent(UserAccelerometerEvent event) {
    // This is a simplified step detection algorithm
    // In a real app, you would use a more sophisticated algorithm
    
    // Get the magnitude of acceleration
    final double magnitude = _calculateMagnitude(event.x, event.y, event.z);
    
    // Use the calculation thread pool for CPU-intensive operations
    _calculationPool.submitTask<bool>('detect_step', {
      'magnitude': magnitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).then((isStep) {
      if (isStep) {
        _incrementSteps();
      }
    });
  }
  
  /// Calculate the magnitude of a 3D vector
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }
  
  /// Increment the step count
  void _incrementSteps() {
    _steps++;
    
    // Update calories burned (rough estimate: ~0.04 calories per step)
    _caloriesBurned = _steps * 0.04;
    
    // Update distance covered (rough estimate: ~0.0008 km per step)
    _distanceCovered = _steps * 0.0008;
    
    // Notify listeners every 5 steps to reduce UI updates
    if (_steps % 5 == 0) {
      notifyListeners();
    }
    
    // Save steps periodically
    if (_steps % 100 == 0) {
      _saveSteps();
    }
  }
  
  /// Reset the step count
  Future<void> resetSteps() async {
    _steps = 0;
    _caloriesBurned = 0;
    _distanceCovered = 0;
    _lastReset = DateTime.now();
    await _saveSteps();
    notifyListeners();
  }
  
  /// Get daily goal progress as a percentage (0.0 to 1.0)
  double getDailyGoalProgress() {
    return _steps / _stepsTarget;
  }
  
  /// Load saved steps from persistent storage
  Future<void> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load steps
    _steps = prefs.getInt('steps') ?? 0;
    
    // Load step target
    _stepsTarget = prefs.getInt('steps_target') ?? 10000;
    
    // Calculate calories and distance
    _caloriesBurned = _steps * 0.04;
    _distanceCovered = _steps * 0.0008;
    
    // Load last reset time
    final lastResetStr = prefs.getString('last_reset');
    if (lastResetStr != null) {
      _lastReset = DateTime.parse(lastResetStr);
    }
    
    // Auto-reset steps if it's a new day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastResetDay = DateTime(_lastReset.year, _lastReset.month, _lastReset.day);
    
    if (today.isAfter(lastResetDay)) {
      await resetSteps();
    }
  }
  
  /// Save steps to persistent storage
  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
    await prefs.setString('last_reset', _lastReset.toIso8601String());
  }
  
  /// Save step target to persistent storage
  Future<void> _saveStepsTarget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_target', _stepsTarget);
  }
  
  /// Calculate calories burned based on steps
  Future<double> calculateCaloriesBurned() async {
    // Use the calculation thread pool for this CPU-intensive operation
    return await _calculationPool.calculateCaloriesBurned(
      weightKg: 70, // Default weight, should be replaced with user's actual weight
      activityType: 'walking',
      durationMinutes: 30, // Estimated based on steps
      intensity: 5, // Medium intensity
    );
  }
  
  /// Get step progress as a percentage
  double getStepProgress() {
    return _steps / _stepsTarget;
  }
  
  @override
  void dispose() {
    stopCounting();
    _sensorManager.dispose();
    _calculationPool.shutdown();
    super.dispose();
  }
  
  // Helper method for sqrt calculation (to avoid importing dart:math)
  double sqrt(double value) {
    // Newton's method for square root approximation
    double guess = value / 2.0;
    for (int i = 0; i < 10; i++) {
      guess = (guess + value / guess) / 2.0;
    }
    return guess;
  }
} 