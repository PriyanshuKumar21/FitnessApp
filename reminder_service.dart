import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_model.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class ReminderService extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  
  // Flutter Local Notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Constructor
  ReminderService(this._authService) {
    _initializeService();
  }
  
  // Getters
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize service
  Future<void> _initializeService() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Initialize time zones
      tz_data.initializeTimeZones();
      
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
          
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
      
      // Load reminders for current user
      await loadReminders();
      
      _error = null;
    } catch (e) {
      _error = "Failed to initialize reminder service: ${e.toString()}";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load reminders for current user
  Future<void> loadReminders() async {
    if (_authService.currentUser == null) {
      _reminders = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = _authService.currentUser!.id;
      _reminders = await _dbHelper.getRemindersForUser(userId);
      _error = null;
    } catch (e) {
      _error = "Failed to load reminders: ${e.toString()}";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new reminder
  Future<bool> addReminder({
    required String title,
    required String message,
    required DateTime reminderTime,
    required String type,
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
      
      final reminder = Reminder(
        userId: userId,
        title: title,
        message: message,
        reminderTime: reminderTime,
        type: type,
      );
      
      final id = await _dbHelper.insertReminder(reminder);
      
      if (id > 0) {
        // Reload reminders
        await loadReminders();
        
        // Schedule notification
        await _scheduleNotification(
          id,
          title,
          message,
          reminderTime,
        );
        
        return true;
      } else {
        _error = "Failed to add reminder";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to add reminder: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update an existing reminder
  Future<bool> updateReminder({
    required int id,
    String? title,
    String? message,
    DateTime? reminderTime,
    bool? isActive,
    String? type,
  }) async {
    if (_authService.currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get the existing reminder
      final existingReminder = await _dbHelper.getReminderById(id);
      
      if (existingReminder == null) {
        _error = "Reminder not found";
        notifyListeners();
        return false;
      }
      
      // Update the reminder
      final updatedReminder = existingReminder.copyWith(
        title: title,
        message: message,
        reminderTime: reminderTime,
        isActive: isActive,
        type: type,
      );
      
      final result = await _dbHelper.updateReminder(updatedReminder);
      
      if (result > 0) {
        // Reload reminders
        await loadReminders();
        
        // Cancel existing notification
        await _flutterLocalNotificationsPlugin.cancel(id);
        
        // Reschedule notification if active
        if (updatedReminder.isActive) {
          await _scheduleNotification(
            id,
            updatedReminder.title,
            updatedReminder.message,
            updatedReminder.reminderTime,
          );
        }
        
        return true;
      } else {
        _error = "Failed to update reminder";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to update reminder: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle reminder active status
  Future<bool> toggleReminderActive(int id, bool isActive) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _dbHelper.toggleReminderActive(id, isActive);
      
      if (result > 0) {
        // Reload reminders
        await loadReminders();
        
        // Get updated reminder
        final reminder = await _dbHelper.getReminderById(id);
        
        if (reminder != null) {
          if (isActive) {
            // Schedule notification
            await _scheduleNotification(
              id,
              reminder.title,
              reminder.message,
              reminder.reminderTime,
            );
          } else {
            // Cancel notification
            await _flutterLocalNotificationsPlugin.cancel(id);
          }
        }
        
        return true;
      } else {
        _error = "Failed to update reminder";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to update reminder: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a reminder
  Future<bool> deleteReminder(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Cancel notification first
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      // Delete from database
      final result = await _dbHelper.deleteReminder(id);
      
      if (result > 0) {
        // Reload reminders
        await loadReminders();
        return true;
      } else {
        _error = "Failed to delete reminder";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Failed to delete reminder: ${e.toString()}";
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Schedule a notification
  Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    try {
      // Skip scheduling if the time has already passed
      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint('Skipping notification scheduling as time has passed: $scheduledDate');
        return;
      }
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fitness_app_reminders',
        'Fitness App Reminders',
        channelDescription: 'Notifications for fitness reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Scheduled notification for: $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
  
  // Get reminders by type
  List<Reminder> getRemindersByType(String type) {
    return _reminders.where((r) => r.type == type).toList();
  }
  
  // Get today's reminders
  List<Reminder> getTodayReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _reminders.where((r) => 
      r.reminderTime.isAfter(today) && 
      r.reminderTime.isBefore(tomorrow)
    ).toList();
  }
  
  // Get upcoming reminders (next 7 days)
  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return _reminders.where((r) => 
      r.reminderTime.isAfter(now) && 
      r.reminderTime.isBefore(nextWeek)
    ).toList();
  }
} 