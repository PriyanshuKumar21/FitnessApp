import 'package:flutter/foundation.dart';
import 'dart:async';

// Mock notification service implementation
class NotificationService extends ChangeNotifier {
  // Mock plugin - not actually used
  final List<Map<String, dynamic>> _scheduledNotifications = [];
  
  // Add timers for workout reminders
  final Map<int, Timer> _countdownTimers = {};
  final List<Map<String, dynamic>> _activeTimers = [];

  // Track which timers are workout timers
  final Map<int, String> _workoutTimers = {};
  
  // Track if this is the first launch to prevent auto-creating demo timers
  bool _hasInitialized = false;

  Future<void> initialize() async {
    debugPrint('Initializing mock notifications service');
    
    // Ensure we only run initialization code once
    if (!_hasInitialized) {
      _hasInitialized = true;
    }
  }

  // Create demo timers only if specifically requested
  void createDemoTimers() {
    // Only create demo timers if explicitly called
    setWorkoutTimer('Warm-up', const Duration(minutes: 5));
    setWorkoutTimer('HIIT Workout', const Duration(minutes: 20));
    setWorkoutTimer('Cool Down', const Duration(minutes: 3));
  }

  Future<void> scheduleWorkoutReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    debugPrint('Scheduled notification: $title at ${scheduledTime.toString()}');
    
    final notification = {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
    };
    
    _scheduledNotifications.add(notification);
    
    // If the notification is scheduled for the future, set up a countdown timer
    final now = DateTime.now();
    if (scheduledTime.isAfter(now)) {
      final duration = scheduledTime.difference(now);
      if (duration.inSeconds > 0) {
        _startCountdownTimer(id, title, duration);
      }
    }
    
    notifyListeners();
  }

  void _startCountdownTimer(int id, String title, Duration duration, {bool isWorkout = false}) {
    // Cancel any existing timer with the same ID
    _countdownTimers[id]?.cancel();
    
    // Add to active timers
    _activeTimers.add({
      'id': id,
      'title': title,
      'remaining': duration,
      'total': duration,
      'isWorkout': isWorkout,
    });
    
    // Track workout timers separately
    if (isWorkout) {
      _workoutTimers[id] = title;
    }
    
    // Start a periodic timer to update the remaining time
    _countdownTimers[id] = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Find the timer data
      final timerIndex = _activeTimers.indexWhere((t) => t['id'] == id);
      if (timerIndex >= 0) {
        final timerData = _activeTimers[timerIndex];
        final remaining = timerData['remaining'] as Duration;
        
        if (remaining.inSeconds <= 1) {
          // Timer complete
          _activeTimers.removeAt(timerIndex);
          timer.cancel();
          _countdownTimers.remove(id);
          if (isWorkout) {
            _workoutTimers.remove(id);
          }
          debugPrint('Timer completed: $title');
        } else {
          // Update remaining time
          _activeTimers[timerIndex]['remaining'] = remaining - const Duration(seconds: 1);
        }
        
        notifyListeners();
      } else {
        // Timer data not found, cancel the timer
        timer.cancel();
        _countdownTimers.remove(id);
        if (isWorkout) {
          _workoutTimers.remove(id);
        }
      }
    });
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('Canceling notification with ID: $id');
    _scheduledNotifications.removeWhere((notification) => notification['id'] == id);
    
    // Cancel any associated timer
    _countdownTimers[id]?.cancel();
    _countdownTimers.remove(id);
    _activeTimers.removeWhere((timer) => timer['id'] == id);
    _workoutTimers.remove(id);
    
    notifyListeners();
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('Canceling all notifications');
    _scheduledNotifications.clear();
    
    // Cancel all timers
    for (final timer in _countdownTimers.values) {
      timer.cancel();
    }
    _countdownTimers.clear();
    _activeTimers.clear();
    _workoutTimers.clear();
    
    notifyListeners();
  }
  
  // Cancel all non-workout timers
  Future<void> cancelAllNonWorkoutTimers() async {
    debugPrint('Canceling all non-workout timers');
    
    // Get list of IDs to cancel (non-workout timers)
    final idsToCancel = _activeTimers
        .where((timer) => timer['isWorkout'] != true)
        .map((timer) => timer['id'] as int)
        .toList();
    
    for (final id in idsToCancel) {
      cancelNotification(id);
    }
  }
  
  // Cancel only workout timers
  Future<void> cancelAllWorkoutTimers() async {
    debugPrint('Canceling all workout timers');
    
    // Get list of workout timer IDs
    final idsToCancel = _workoutTimers.keys.toList();
    
    for (final id in idsToCancel) {
      cancelNotification(id);
    }
  }
  
  // Additional method to get all scheduled notifications (for UI display)
  List<Map<String, dynamic>> getScheduledNotifications() {
    return List.from(_scheduledNotifications);
  }
  
  // Get all active timers
  List<Map<String, dynamic>> getActiveTimers() {
    return List.from(_activeTimers);
  }
  
  // Get only workout timers
  List<Map<String, dynamic>> getActiveWorkoutTimers() {
    return _activeTimers
        .where((timer) => timer['isWorkout'] == true)
        .toList();
  }
  
  // Set a workout timer
  void setWorkoutTimer(String workoutName, Duration duration) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final title = 'Workout Timer: $workoutName';
    
    _startCountdownTimer(id, title, duration, isWorkout: true);
  }
  
  // Calculate the progress of a timer (0.0 to 1.0)
  double getTimerProgress(int id) {
    final timerData = _activeTimers.firstWhere(
      (t) => t['id'] == id, 
      orElse: () => {'total': const Duration(seconds: 1), 'remaining': const Duration(seconds: 0)}
    );
    
    final total = (timerData['total'] as Duration).inSeconds;
    final remaining = (timerData['remaining'] as Duration).inSeconds;
    
    if (total <= 0) return 0.0;
    return 1.0 - (remaining / total);
  }
  
  // Format remaining time as mm:ss
  String formatRemainingTime(int id) {
    final timerData = _activeTimers.firstWhere(
      (t) => t['id'] == id, 
      orElse: () => {'remaining': const Duration(seconds: 0)}
    );
    
    final remaining = timerData['remaining'] as Duration;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _countdownTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
} 