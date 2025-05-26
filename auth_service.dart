import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'achievement_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  
  // Database helper
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Authentication state
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  
  // Constructor - initialize the service
  AuthService() {
    _initializeService();
  }
  
  // Initialize service and check for existing login
  Future<void> _initializeService() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create demo users for testing (only if they don't exist)
      await _createDemoUsersIfNeeded();
      
      // We don't want auto-login so user always starts at login screen
      // await _loadUserFromLocalStorage();
      
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = "Failed to initialize auth service: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create demo users for testing
  Future<void> _createDemoUsersIfNeeded() async {
    try {
      // Check if the demo users already exist
      final user1 = await _dbHelper.getUserByEmail('john@example.com');
      
      if (user1 == null) {
        // Create demo users
        final demoUser1 = User(
          id: 'user1',
          name: 'John Doe',
          email: 'john@example.com',
          photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
          registrationDate: DateTime.now().subtract(const Duration(days: 30)),
          isVerified: true,
        );
        
        final demoUser2 = User(
          id: 'user2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          photoUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
          registrationDate: DateTime.now().subtract(const Duration(days: 15)),
          isVerified: true,
        );
        
        // Insert users with password 'password'
        final hashedPassword = _hashPassword('password');
        await _dbHelper.insertUser(demoUser1, hashedPassword);
        await _dbHelper.insertUser(demoUser2, hashedPassword);
      }
    } catch (e) {
      debugPrint('Error creating demo users: ${e.toString()}');
    }
  }
  
  // Load user from local storage (shared preferences)
  Future<void> _loadUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId != null) {
      try {
        final user = await _dbHelper.getUserById(userId);
        _currentUser = user;
      } catch (e) {
        // Invalid user data in storage
        await prefs.remove('userId');
        _currentUser = null;
      }
    }
  }
  
  // Save user ID to local storage
  Future<void> _saveUserIdToLocalStorage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
  
  // Remove user ID from local storage
  Future<void> _removeUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
  
  // Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get user by email
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user == null) {
        _error = "User not found. Please check your email or register.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Get stored password hash
      final storedHash = await _dbHelper.getPasswordHashByEmail(email);
      
      // Hash the provided password for comparison
      final providedHash = _hashPassword(password);
      
      // Compare password hashes
      if (storedHash == providedHash) {
        _currentUser = user;
        
        // Save user ID to local storage
        await _saveUserIdToLocalStorage(user.id);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Incorrect password. Please try again.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Login failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Register a new user
  Future<bool> register(String name, String email, String password, {String gender = 'male'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('=== REGISTRATION PROCESS STARTED ===');
      debugPrint('Attempting to register user: $name, Email: $email');
      
      // Check if email is already registered
      try {
        final existingUser = await _dbHelper.getUserByEmail(email);
        
        if (existingUser != null) {
          _error = "Email already registered. Please login instead.";
          debugPrint('Registration failed: Email already registered');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('Error checking existing user: $e');
      }
      
      // Generate a unique user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Hash the password
      final passwordHash = await _hashPassword(password);
      
      // Create user object
      final user = User(
        id: userId,
        name: name,
        email: email,
        registrationDate: DateTime.now(),
        gender: gender,
      );
      
      // Save user to database
      debugPrint('Saving user to database...');
      await _dbHelper.insertUser(user, passwordHash);
      
      // Set current user
      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      
      debugPrint('Registration successful for user: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Registration failed: ${e.toString()}";
      debugPrint('Registration error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Direct login with user object (for Excel import)
  Future<bool> loginWithUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Set as current user
      _currentUser = user;
      
      // Save user ID to local storage
      await _saveUserIdToLocalStorage(user.id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Direct login failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = null;
      await _removeUserFromLocalStorage();
    } catch (e) {
      _error = "Logout failed: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if user exists
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user != null) {
        // In a real app, you would send a password reset email here
        // For demo purposes, we'll reset the password to 'newpassword'
        final newPasswordHash = _hashPassword('newpassword');
        
        // Update user in database (basic info)
        await _dbHelper.updateUser(user);
        
        // Update password hash in user_auth table
        final db = await _dbHelper.database;
        await db.update(
          'user_auth',
          {'password_hash': newPasswordHash},
          where: 'user_id = ?',
          whereArgs: [user.id],
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Email not found. Please check your email or register.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Password reset failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({String? name, String? photoUrl, String? gender}) async {
    if (_currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Update user object
      _currentUser = _currentUser!.copyWith(
        name: name,
        photoUrl: photoUrl,
        gender: gender,
      );
      
      // Update in database
      await _dbHelper.updateUser(_currentUser!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Profile update failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Save user profile details
  Future<bool> saveUserProfileDetails({
    required int height,
    required int weight,
    required int age,
    required String fitnessGoal,
    String? gender,
    int? dailyStepTarget,
    int? weeklyWorkoutTarget,
  }) async {
    if (_currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Update gender in user object if provided
      if (gender != null) {
        _currentUser = _currentUser!.copyWith(gender: gender);
        await _dbHelper.updateUser(_currentUser!);
      }
      
      // Save profile details
      await _dbHelper.saveUserProfile(
        userId: _currentUser!.id,
        height: height,
        weight: weight,
        age: age,
        fitnessGoal: fitnessGoal,
        dailyStepTarget: dailyStepTarget,
        weeklyWorkoutTarget: weeklyWorkoutTarget,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Profile details update failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get user profile details
  Future<Map<String, dynamic>?> getUserProfileDetails() async {
    if (_currentUser == null) {
      return null;
    }
    
    try {
      return await _dbHelper.getUserProfile(_currentUser!.id);
    } catch (e) {
      _error = "Failed to get profile details: ${e.toString()}";
      notifyListeners();
      return null;
    }
  }
  
  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      return await _dbHelper.getUserByEmail(email);
    } catch (e) {
      _error = "Failed to get user by email: ${e.toString()}";
      notifyListeners();
      return null;
    }
  }
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get stored password hash
      final storedHash = await _dbHelper.getPasswordHashByEmail(_currentUser!.email);
      
      // Hash the provided current password for comparison
      final currentPasswordHash = _hashPassword(currentPassword);
      
      // Compare password hashes
      if (storedHash == currentPasswordHash) {
        // Hash the new password
        final newPasswordHash = _hashPassword(newPassword);
        
        // Update password hash in database
        final db = await _dbHelper.database;
        await db.update(
          'user_auth',
          {'password_hash': newPasswordHash},
          where: 'user_id = ?',
          whereArgs: [_currentUser!.id],
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Current password is incorrect";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Password change failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Record workout
  Future<bool> recordWorkout(String workoutName, int durationMinutes, int caloriesBurned) async {
    if (_currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    try {
      await _dbHelper.insertWorkoutHistory(
        _currentUser!.id,
        workoutName,
        DateTime.now(),
        durationMinutes,
        caloriesBurned,
      );
      
      return true;
    } catch (e) {
      _error = "Failed to record workout: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
  
  // Get workout history
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    if (_currentUser == null) {
      return [];
    }
    
    try {
      return await _dbHelper.getWorkoutHistoryForUser(_currentUser!.id);
    } catch (e) {
      _error = "Failed to get workout history: ${e.toString()}";
      notifyListeners();
      return [];
    }
  }
  
  // Record step count
  Future<bool> recordSteps(int steps) async {
    if (_currentUser == null) {
      _error = "No user is logged in";
      notifyListeners();
      return false;
    }
    
    try {
      await _dbHelper.insertStepCount(
        _currentUser!.id,
        DateTime.now(),
        steps,
      );
      
      return true;
    } catch (e) {
      _error = "Failed to record steps: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
  
  // Get step history
  Future<List<Map<String, dynamic>>> getStepHistory({DateTime? startDate, DateTime? endDate}) async {
    if (_currentUser == null) {
      return [];
    }
    
    try {
      return await _dbHelper.getStepCountsForUser(
        _currentUser!.id,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = "Failed to get step history: ${e.toString()}";
      notifyListeners();
      return [];
    }
  }
} 