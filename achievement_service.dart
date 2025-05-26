import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  
  // Get default achievements list
  static List<Map<String, dynamic>> getDefaultAchievements() {
    return [
      {
        'name': 'Early Bird',
        'description': 'Complete 5 workouts before 8 AM',
        'icon': FontAwesomeIcons.sun,
        'color': Colors.amber,
        'completed': false,
        'progress': 0.0,
      },
      {
        'name': 'Marathon Runner',
        'description': 'Run a total of 42 km',
        'icon': FontAwesomeIcons.personRunning,
        'color': Colors.blue,
        'completed': false,
        'progress': 0.0,
      },
      {
        'name': 'Consistency King',
        'description': 'Complete workouts for 30 consecutive days',
        'icon': FontAwesomeIcons.crown,
        'color': Colors.purple,
        'completed': false,
        'progress': 0.0,
      },
      {
        'name': 'Power Lifter',
        'description': 'Lift a total of 1000 kg in a single session',
        'icon': FontAwesomeIcons.dumbbell,
        'color': Colors.red,
        'completed': false,
        'progress': 0.0,
      },
    ];
  }
  
  // Save achievements for a user
  static Future<void> saveAchievements(String userId, List<Map<String, dynamic>> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = achievements.map((a) {
        // Convert Color to int for storage
        final Map<String, dynamic> achievementMap = Map.from(a);
        if (achievementMap['color'] is Color) {
          achievementMap['color'] = (achievementMap['color'] as Color).value;
        }
        // Convert IconData to int for storage
        if (achievementMap['icon'] is IconData) {
          achievementMap['icon'] = (achievementMap['icon'] as IconData).codePoint;
          achievementMap['icon_family'] = (achievementMap['icon'] as IconData).fontFamily;
          achievementMap['icon_package'] = (achievementMap['icon'] as IconData).fontPackage;
        }
        return achievementMap;
      }).toList();
      
      await prefs.setString('${_achievementsKey}_$userId', jsonEncode(achievementsJson));
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }
  
  // Load achievements for a user
  static Future<List<Map<String, dynamic>>> loadAchievements(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsString = prefs.getString('${_achievementsKey}_$userId');
      
      if (achievementsString == null) {
        // If no achievements found, return default achievements
        return getDefaultAchievements();
      }
      
      final achievementsJson = jsonDecode(achievementsString) as List;
      return achievementsJson.map((a) {
        final Map<String, dynamic> achievementMap = Map.from(a);
        // Convert int back to Color
        if (achievementMap['color'] is int) {
          achievementMap['color'] = Color(achievementMap['color'] as int);
        }
        // Convert int back to IconData
        if (achievementMap['icon'] is int) {
          achievementMap['icon'] = IconData(
            achievementMap['icon'] as int,
            fontFamily: achievementMap['icon_family'] as String?,
            fontPackage: achievementMap['icon_package'] as String?,
          );
        }
        return achievementMap;
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      // Return default achievements on error
      return getDefaultAchievements();
    }
  }
  
  // Reset achievements for a user
  static Future<void> resetAchievements(String userId) async {
    try {
      await saveAchievements(userId, getDefaultAchievements());
    } catch (e) {
      debugPrint('Error resetting achievements: $e');
    }
  }
} 