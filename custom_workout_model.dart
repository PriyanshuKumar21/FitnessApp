import 'package:flutter/material.dart';

class CustomWorkout {
  final int? id;
  final String userId;
  final String name;
  final String type;
  final String description;
  final String duration;
  final int calories;
  final String difficulty;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> exercises;
  final DateTime createdAt;

  CustomWorkout({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.description,
    required this.duration,
    required this.calories,
    required this.color,
    required this.icon,
    required this.exercises,
    required this.difficulty,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'description': description,
      'duration': duration,
      'calories': calories,
      'difficulty': difficulty,
      'color_value': color.value,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'icon_font_package': icon.fontPackage,
      'exercises': exercises.map((e) => e.toString()).toList().toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CustomWorkout.fromMap(Map<String, dynamic> map) {
    // Parse exercises from string
    String exercisesStr = map['exercises'] ?? '[]';
    List<Map<String, dynamic>> exercisesList = [];
    
    try {
      // Remove the outer brackets and split by '},{'
      exercisesStr = exercisesStr.substring(1, exercisesStr.length - 1);
      List<String> exerciseStrings = exercisesStr.split('}, {');
      
      for (var i = 0; i < exerciseStrings.length; i++) {
        String exStr = exerciseStrings[i];
        if (i == 0) exStr = exStr.startsWith('{') ? exStr : '{$exStr';
        if (i == exerciseStrings.length - 1) exStr = exStr.endsWith('}') ? exStr : '$exStr}';
        
        // Convert string to map
        Map<String, dynamic> exercise = {};
        exStr = exStr.replaceAll('{', '').replaceAll('}', '');
        List<String> pairs = exStr.split(', ');
        
        for (var pair in pairs) {
          List<String> keyValue = pair.split(': ');
          if (keyValue.length == 2) {
            String key = keyValue[0].trim();
            String value = keyValue[1].trim();
            // Remove quotes if present
            if (key.startsWith("'") && key.endsWith("'")) {
              key = key.substring(1, key.length - 1);
            }
            if (value.startsWith("'") && value.endsWith("'")) {
              value = value.substring(1, value.length - 1);
            }
            exercise[key] = value;
          }
        }
        
        if (exercise.isNotEmpty) {
          exercisesList.add(exercise);
        }
      }
    } catch (e) {
      debugPrint('Error parsing exercises: $e');
    }

    return CustomWorkout(
      id: map['id'],
      userId: map['user_id'] ?? '',
      name: map['name'] ?? 'Custom Workout',
      type: map['type'] ?? 'General',
      description: map['description'] ?? 'A custom workout',
      duration: map['duration'] ?? '30 min',
      calories: map['calories'] ?? 200,
      difficulty: map['difficulty'] ?? 'Medium',
      color: Color(map['color_value'] ?? Colors.blue.value),
      icon: IconData(
        map['icon_code_point'] ?? Icons.fitness_center.codePoint,
        fontFamily: map['icon_font_family'],
        fontPackage: map['icon_font_package'],
      ),
      exercises: exercisesList,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : DateTime.now(),
    );
  }

  // Convert to a format compatible with WorkoutDetailScreen
  Map<String, dynamic> toWorkoutMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'duration': duration,
      'calories': calories,
      'difficulty': difficulty,
      'color': color,
      'icon': icon,
      'exercises': exercises,
      'isCustom': true,
    };
  }
} 