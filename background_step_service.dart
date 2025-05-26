import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A background service for step counting that continues to work when the app is minimized
class BackgroundStepService {
  static final BackgroundStepService _instance = BackgroundStepService._internal();
  factory BackgroundStepService() => _instance;
  
  BackgroundStepService._internal();
  
  // Stream subscriptions
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  
  // Step data
  int _steps = 0;
  int _lastSavedSteps = 0;
  DateTime _lastSaveTime = DateTime.now();
  
  // Isolate for background processing
  Isolate? _backgroundIsolate;
  ReceivePort? _receivePort;
  
  // Notification plugin for persistent notification
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  /// Initialize the background step service
  Future<void> initialize() async {
    // Initialize notifications
    await _initializeNotifications();
    
    // Load last saved steps
    await _loadSavedSteps();
    
    // Start step counting
    await _startStepCounting();
    
    // Show persistent notification
    _showPersistentNotification();
  }
  
  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }
  
  /// Start step counting in the background
  Future<void> _startStepCounting() async {
    // Create a receive port for communication with the isolate
    _receivePort = ReceivePort();
    
    // Start listening to the pedometer
    _initPedometer();
    
    // Start background isolate for periodic saving
    _backgroundIsolate = await Isolate.spawn(
      _backgroundSaveSteps,
      _receivePort!.sendPort,
    );
    
    // Listen for messages from the background isolate
    _receivePort!.listen((message) {
      if (message == 'save_steps') {
        _saveSteps();
      }
    });
  }
  
  /// Initialize the pedometer
  void _initPedometer() {
    // Listen for steps
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
    
    // Listen for pedestrian status
    _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatusChanged,
      onError: _onPedestrianStatusError,
      cancelOnError: true,
    );
  }
  
  /// Handle step count updates
  void _onStepCount(StepCount event) {
    _steps = event.steps;
    
    // Update the persistent notification
    _updatePersistentNotification();
    
    // Save steps periodically
    final now = DateTime.now();
    if (now.difference(_lastSaveTime).inMinutes >= 5) {
      _saveSteps();
      _lastSaveTime = now;
    }
  }
  
  /// Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    debugPrint('Pedestrian status: ${event.status}');
  }
  
  /// Handle step count errors
  void _onStepCountError(error) {
    debugPrint('Step count error: $error');
  }
  
  /// Handle pedestrian status errors
  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian status error: $error');
  }
  
  /// Background isolate function for periodic saving
  static void _backgroundSaveSteps(SendPort sendPort) {
    // Create a timer that sends a message to the main isolate every 10 minutes
    Timer.periodic(const Duration(minutes: 10), (_) {
      sendPort.send('save_steps');
    });
  }
  
  /// Save steps to persistent storage
  Future<void> _saveSteps() async {
    if (_steps > _lastSavedSteps) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_saved_steps', _steps);
      await prefs.setString('last_save_time', DateTime.now().toIso8601String());
      _lastSavedSteps = _steps;
    }
  }
  
  /// Load saved steps from persistent storage
  Future<void> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSavedSteps = prefs.getInt('last_saved_steps') ?? 0;
    final lastSaveTimeStr = prefs.getString('last_save_time');
    if (lastSaveTimeStr != null) {
      _lastSaveTime = DateTime.parse(lastSaveTimeStr);
    }
  }
  
  /// Show a persistent notification to keep the service alive
  Future<void> _showPersistentNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'step_counter_channel',
      'Step Counter',
      channelDescription: 'Shows the current step count',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      0,
      'Step Counter Active',
      'Steps today: $_steps',
      platformChannelSpecifics,
    );
  }
  
  /// Update the persistent notification with the current step count
  Future<void> _updatePersistentNotification() async {
    await _notificationsPlugin.show(
      0,
      'Step Counter Active',
      'Steps today: $_steps',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'step_counter_channel',
          'Step Counter',
          channelDescription: 'Shows the current step count',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
        ),
      ),
    );
  }
  
  /// Get the current step count
  int getStepCount() {
    return _steps;
  }
  
  /// Stop the background service
  Future<void> stop() async {
    // Save steps before stopping
    await _saveSteps();
    
    // Cancel subscriptions
    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    
    // Kill the background isolate
    _backgroundIsolate?.kill(priority: Isolate.immediate);
    _backgroundIsolate = null;
    _receivePort?.close();
    _receivePort = null;
    
    // Remove the persistent notification
    await _notificationsPlugin.cancel(0);
  }
} 