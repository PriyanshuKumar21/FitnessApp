import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class DirectLoginService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Direct login without password
  Future<User?> directLoginFromExcel(String email) async {
    try {
      // Get user from database
      final user = await _dbHelper.getUserByEmail(email);
      return user;
    } catch (e) {
      debugPrint('Error finding user for direct login: $e');
      return null;
    }
  }
} 