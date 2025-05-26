import 'package:flutter/material.dart';
import '../services/background_step_service.dart';
import '../services/calculation_thread_pool.dart';
import '../services/sensor_resource_manager.dart';
import '../services/step_counter_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'package:provider/provider.dart';

class OSConceptsDemoScreen extends StatefulWidget {
  const OSConceptsDemoScreen({super.key});

  @override
  State<OSConceptsDemoScreen> createState() => _OSConceptsDemoScreenState();
}

class _OSConceptsDemoScreenState extends State<OSConceptsDemoScreen> {
  final BackgroundStepService _backgroundService = BackgroundStepService();
  final CalculationThreadPool _calculationPool = CalculationThreadPool();
  final SensorResourceManager _sensorManager = SensorResourceManager();
  
  bool _isBackgroundServiceRunning = false;
  bool _isThreadPoolInitialized = false;
  int _activeWorkers = 0;
  int _pendingTasks = 0;
  
  // Sensor usage stats
  bool _isAccelerometerActive = false;
  bool _isGyroscopeActive = false;
  bool _isUserAccelerometerActive = false;
  
  // Calculation results
  double? _bmiResult;
  double? _caloriesBurnedResult;
  Map<String, double>? _dailyCaloriesResult;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    await _calculationPool.initialize();
    setState(() {
      _isThreadPoolInitialized = true;
    });
    
    _sensorManager.initialize();
    
    // Check sensor status periodically
    Future.delayed(const Duration(seconds: 1), () {
      _updateSensorStatus();
    });
  }
  
  void _updateSensorStatus() {
    setState(() {
      _isAccelerometerActive = _sensorManager.isResourceInUse('accelerometer');
      _isGyroscopeActive = _sensorManager.isResourceInUse('gyroscope');
      _isUserAccelerometerActive = _sensorManager.isResourceInUse('userAccelerometer');
    });
    
    // Update again after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateSensorStatus();
      }
    });
  }
  
  Future<void> _toggleBackgroundService() async {
    if (_isBackgroundServiceRunning) {
      await _backgroundService.stop();
    } else {
      await _backgroundService.initialize();
    }
    
    setState(() {
      _isBackgroundServiceRunning = !_isBackgroundServiceRunning;
    });
  }
  
  Future<void> _calculateBMI() async {
    setState(() {
      _activeWorkers++;
      _pendingTasks++;
    });
    
    try {
      final result = await _calculationPool.calculateBMI(
        weightKg: 70.0,
        heightCm: 175.0,
      );
      
      setState(() {
        _bmiResult = result;
        _pendingTasks--;
      });
    } finally {
      setState(() {
        _activeWorkers--;
      });
    }
  }
  
  Future<void> _calculateCaloriesBurned() async {
    setState(() {
      _activeWorkers++;
      _pendingTasks++;
    });
    
    try {
      final result = await _calculationPool.calculateCaloriesBurned(
        weightKg: 70.0,
        activityType: 'running',
        durationMinutes: 30,
        intensity: 7,
      );
      
      setState(() {
        _caloriesBurnedResult = result;
        _pendingTasks--;
      });
    } finally {
      setState(() {
        _activeWorkers--;
      });
    }
  }
  
  Future<void> _calculateDailyCalories() async {
    setState(() {
      _activeWorkers++;
      _pendingTasks++;
    });
    
    try {
      final result = await _calculationPool.calculateDailyCalorieNeeds(
        weightKg: 70.0,
        heightCm: 175.0,
        ageYears: 30,
        gender: 'male',
        activityLevel: 'moderate',
      );
      
      setState(() {
        _dailyCaloriesResult = result;
        _pendingTasks--;
      });
    } finally {
      setState(() {
        _activeWorkers--;
      });
    }
  }
  
  Future<void> _startStepCounting() async {
    final stepCounterService = Provider.of<StepCounterService>(context, listen: false);
    await stepCounterService.startCounting();
  }
  
  Future<void> _stopStepCounting() async {
    final stepCounterService = Provider.of<StepCounterService>(context, listen: false);
    await stepCounterService.stopCounting();
  }
  
  @override
  Widget build(BuildContext context) {
    final stepCounterService = Provider.of<StepCounterService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('OS Concepts Demo'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Background Service Section
            const Text(
              '1. Background Service (Process Management)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_isBackgroundServiceRunning ? "Running" : "Stopped"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The background service keeps counting steps even when the app is minimized, using a foreground service with a persistent notification.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _toggleBackgroundService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isBackgroundServiceRunning ? Colors.red : AppTheme.primaryColor,
                        ),
                        child: Text(_isBackgroundServiceRunning ? 'Stop Service' : 'Start Service'),
                      ),
                      Text(
                        'Steps: ${stepCounterService.steps}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thread Pool Section
            const Text(
              '2. Thread Pool (Concurrency)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_isThreadPoolInitialized ? "Initialized" : "Not Initialized"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active Workers: $_activeWorkers / 4',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Pending Tasks: $_pendingTasks',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The thread pool manages concurrent calculations using isolates, distributing CPU-intensive tasks across multiple workers.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _calculateBMI,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Calculate BMI'),
                      ),
                      ElevatedButton(
                        onPressed: _calculateCaloriesBurned,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Calculate Calories'),
                      ),
                      ElevatedButton(
                        onPressed: _calculateDailyCalories,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Daily Needs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_bmiResult != null)
                    Text(
                      'BMI Result: ${_bmiResult!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (_caloriesBurnedResult != null)
                    Text(
                      'Calories Burned: ${_caloriesBurnedResult!.toStringAsFixed(2)} kcal',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (_dailyCaloriesResult != null) ...[
                    Text(
                      'Daily Calorie Needs: ${_dailyCaloriesResult!['tdee']?.toStringAsFixed(2)} kcal',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Protein: ${_dailyCaloriesResult!['protein_g']?.toStringAsFixed(2)}g, Fat: ${_dailyCaloriesResult!['fat_g']?.toStringAsFixed(2)}g, Carbs: ${_dailyCaloriesResult!['carbs_g']?.toStringAsFixed(2)}g',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resource Allocation Section
            const Text(
              '3. Resource Allocation (Sensor Management)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensor Status:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildSensorStatusRow('Accelerometer', _isAccelerometerActive),
                  _buildSensorStatusRow('Gyroscope', _isGyroscopeActive),
                  _buildSensorStatusRow('User Accelerometer', _isUserAccelerometerActive),
                  const SizedBox(height: 8),
                  const Text(
                    'The resource manager controls access to sensors, manages priorities, and optimizes battery usage.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _startStepCounting(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Request Sensors'),
                      ),
                      ElevatedButton(
                        onPressed: () => _stopStepCounting(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Release Sensors'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSensorStatusRow(String sensorName, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sensorName,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _calculationPool.shutdown();
    super.dispose();
  }
} 