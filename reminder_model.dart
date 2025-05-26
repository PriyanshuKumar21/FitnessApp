import 'package:flutter/foundation.dart';

class Reminder {
  final int? id;
  final String userId;
  final String title;
  final String message;
  final DateTime reminderTime;
  final bool isActive;
  final String type; // workout, water, medication, etc.

  Reminder({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.reminderTime,
    this.isActive = true,
    required this.type,
  });

  // Convert Reminder object to a map for storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'reminder_time': reminderTime.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'type': type,
    };
  }

  // Create a Reminder object from a map (e.g., from storage)
  factory Reminder.fromMap(Map<String, dynamic> map) {
    // Debug: Print the map contents to see what we're working with
    debugPrint('Creating Reminder from map: $map');
    
    bool isActive = false;
    // Handle different possible types for is_active
    if (map['is_active'] != null) {
      if (map['is_active'] is bool) {
        isActive = map['is_active'];
      } else if (map['is_active'] is int) {
        isActive = map['is_active'] == 1;
      } else if (map['is_active'] is String) {
        isActive = map['is_active'] == '1' || map['is_active'].toLowerCase() == 'true';
      }
    }
    
    // Handle reminder time
    DateTime reminderTime;
    try {
      if (map['reminder_time'] != null) {
        if (map['reminder_time'] is int) {
          reminderTime = DateTime.fromMillisecondsSinceEpoch(map['reminder_time']);
        } else {
          reminderTime = DateTime.parse(map['reminder_time'].toString());
        }
      } else {
        reminderTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error parsing reminder time: $e');
      reminderTime = DateTime.now();
    }
    
    return Reminder(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      reminderTime: reminderTime,
      isActive: isActive,
      type: map['type'] ?? 'general',
    );
  }

  // Create a copy of a Reminder with updated properties
  Reminder copyWith({
    int? id,
    String? userId,
    String? title,
    String? message,
    DateTime? reminderTime,
    bool? isActive,
    String? type,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
    );
  }
} 