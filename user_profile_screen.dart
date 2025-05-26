import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import '../widgets/background_effects.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dart:ui';
import 'profile_settings_screen.dart';
import '../widgets/glowing_icon_button.dart';
import '../services/achievement_service.dart';
import '../services/calculation_thread_pool.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Default stats data (will be linked to user in the future)
  Map<String, dynamic> _statsData = {
    'height': 175, // cm
    'weight': 70, // kg
    'age': 28,
    'goal': 'Lose weight',
    'workoutsCompleted': 87,
    'streakDays': 14,
    'totalCaloriesBurned': 12450,
  };

  // BMI and calorie data
  double _bmi = 0.0;
  Map<String, double> _calorieNeeds = {};
  String _bmiCategory = '';
  String _selectedGoal = 'maintain'; // 'maintain', 'gain', or 'lose'

  List<Map<String, dynamic>> _achievements = [];
  final CalculationThreadPool _calculationPool = CalculationThreadPool();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Log that we're loading the user profile
    debugPrint('Loading User Profile Screen');
    
    // Load user stats when the profile screen initializes
    _loadUserStats();
    
    // Load user achievements
    _loadAchievements();
    
    // Calculate BMI and calorie needs
    _calculateBMIAndCalories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _calculateBMIAndCalories() async {
    // Get the current authenticated user
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? currentUser = authService.currentUser;
    
    // Calculate BMI directly using the formula: BMI = weight(kg) / (height(m) * height(m))
    final heightM = _statsData['height'] / 100.0;
    final weightKg = _statsData['weight'].toDouble();
    final bmi = weightKg / (heightM * heightM);
    
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    final gender = currentUser?.gender ?? 'male'; // Get gender from user model
    final ageYears = _statsData['age'];
    
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weightKg + 6.25 * _statsData['height'] - 5 * ageYears + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * _statsData['height'] - 5 * ageYears - 161;
    }
    
    // Activity multipliers
    final Map<String, double> activityMultipliers = {
      'sedentary': 1.2,      // Little or no exercise
      'light': 1.375,        // Light exercise 1-3 days/week
      'moderate': 1.55,      // Moderate exercise 3-5 days/week
      'active': 1.725,       // Heavy exercise 6-7 days/week
      'very_active': 1.9,    // Very heavy exercise, physical job or training twice a day
    };
    
    final activityLevel = 'moderate'; // This should be dynamic based on user data
    final multiplier = activityMultipliers[activityLevel] ?? activityMultipliers['moderate']!;
    
    // Calculate total daily energy expenditure (TDEE)
    final tdee = bmr * multiplier;
    
    // Adjust calories based on goal
    double adjustedTdee = tdee;
    if (_selectedGoal == 'gain') {
      adjustedTdee = tdee + 300; // Caloric surplus for weight gain
    } else if (_selectedGoal == 'lose') {
      adjustedTdee = tdee - 300; // Caloric deficit for weight loss
    }
    
    // Determine BMI category
    String bmiCategory = '';
    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      bmiCategory = 'Normal weight';
    } else if (bmi >= 25 && bmi < 30) {
      bmiCategory = 'Overweight';
    } else {
      bmiCategory = 'Obese';
    }
    
    // Calculate macronutrient needs
    final proteinG = weightKg * 1.6;
    final proteinCalories = proteinG * 4;
    final fatCalories = adjustedTdee * 0.25;
    final fatG = fatCalories / 9;
    final carbCalories = adjustedTdee - proteinCalories - fatCalories;
    final carbG = carbCalories / 4;
    
    setState(() {
      _bmi = bmi;
      _bmiCategory = bmiCategory;
      _calorieNeeds = {
        'tdee': tdee,
        'adjusted_tdee': adjustedTdee,
        'bmr': bmr,
        'protein_g': proteinG,
        'fat_g': fatG,
        'carbs_g': carbG,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current authenticated user from AuthService
    final authService = Provider.of<AuthService>(context);
    final User? currentUser = authService.currentUser;
    
    // Log the current user
    debugPrint('Building User Profile Screen for user: ${currentUser?.name ?? "Unknown"}');
    
    // If no user is authenticated, show a message
    if (currentUser == null) {
      return const Center(
        child: Text('No user logged in'),
      );
    }
    
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Add top padding to account for the removed header
              const SizedBox(height: 80),
              _buildProfileHeader(currentUser),
              _buildStatsSection(),
              _buildAchievementsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 45,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? _getImageProvider(user.photoUrl)
                    : null,
                backgroundColor: Colors.grey[800],
                child: user.photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: AppTheme.primaryColor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem('Height', '${_statsData['height']} cm'),
              _buildInfoItem('Weight', '${_statsData['weight']} kg'),
              _buildInfoItem('Age', '${_statsData['age']} yrs'),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedGlowButton(
            text: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
              );
            },
            color: AppTheme.primaryColor,
            textColor: Colors.black,
            width: 180,
            height: 44,
            icon: Icons.edit,
            addRipple: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return GlassContainer(
      height: 70,
      width: 90,
      borderRadius: 12,
      padding: const EdgeInsets.all(8),
      opaque: true,
      addGlow: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Targets Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTargetItem(
                      'Daily Steps',
                      '${_statsData['dailyStepTarget'] ?? 10000}',
                      Icons.directions_walk,
                      Colors.blue,
                    ),
                    _buildTargetItem(
                      'Weekly Workouts',
                      '${_statsData['weeklyWorkoutTarget'] ?? 3}',
                      Icons.fitness_center,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // BMI Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BMI (Body Mass Index)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBMICategoryColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _bmiCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Formula: BMI = weight(kg) / height²(m)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Calorie Needs Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Calorie Needs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Goal selection
                Row(
                  children: [
                    const Text('Goal:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedGoal,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      underline: Container(
                        height: 2,
                        color: AppTheme.primaryColor,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedGoal = newValue;
                          });
                          _calculateBMIAndCalories();
                        }
                      },
                      items: <String>['maintain', 'gain', 'lose']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.substring(0, 1).toUpperCase() + value.substring(1),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Calories display
                Center(
                  child: Column(
                    children: [
                      Text(
                        _calorieNeeds.containsKey('adjusted_tdee') 
                            ? '${_calorieNeeds['adjusted_tdee']?.round() ?? 0}'
                            : '0',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Text(
                        'calories/day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Formula explanation
                Center(
                  child: Text(
                    'Formula: BMR × Activity Multiplier ${_selectedGoal != 'maintain' ? (_selectedGoal == 'gain' ? '+ 300' : '- 300') : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Macronutrients
                const Text(
                  'Recommended Macronutrients:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacronutrient(
                      'Protein',
                      '${_calorieNeeds['protein_g']?.round() ?? 0}g',
                      Colors.red[400]!,
                    ),
                    _buildMacronutrient(
                      'Carbs',
                      '${_calorieNeeds['carbs_g']?.round() ?? 0}g',
                      Colors.green[400]!,
                    ),
                    _buildMacronutrient(
                      'Fat',
                      '${_calorieNeeds['fat_g']?.round() ?? 0}g',
                      Colors.yellow[400]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTargetItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrient(String name, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GlowingIconButton(
                icon: Icons.refresh,
                onPressed: _resetAchievements,
                size: 24,
                color: Colors.red,
                tooltip: 'Reset Achievements',
              ),
            ],
          ),
          const SizedBox(height: 16),
          CyberPanel(
            borderColor: const Color(0xFF00E5FF),
            gradientColors: const [Color(0xFF101010), Color(0xFF1A1A1A)],
            cornerSize: 30,
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    addShimmer: achievement['completed'],
                    child: Row(
                      children: [
                        GlowingContainer(
                          glowColor: achievement['color'],
                          height: 50,
                          width: 50,
                          borderRadius: 25,
                          padding: EdgeInsets.zero,
                          glowIntensity: achievement['completed'] ? 0.5 : 0.2,
                          animate: achievement['completed'],
                          child: Center(
                            child: FaIcon(
                              achievement['icon'],
                              color: achievement['color'],
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                achievement['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        achievement['completed']
                            ? Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              )
                            : SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: achievement['progress'],
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    achievement['color'],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Method to reset all achievements
  void _resetAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Reset Achievements'),
        content: const Text('Are you sure you want to reset all achievements? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final User? currentUser = authService.currentUser;
              
              if (currentUser != null) {
                // Reset achievements using the service
                await AchievementService.resetAchievements(currentUser.id);
                
                // Reload achievements
                await _loadAchievements();
              }
              
              // Show confirmation
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All achievements have been reset'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Load user stats from the database
  Future<void> _loadUserStats() async {
    // Get the current user
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      try {
        // Load user profile details
        final userProfile = await authService.getUserProfileDetails();
        
        // Get height, weight, age from profile if available
        final height = userProfile?['height'] as int? ?? _statsData['height'];
        final weight = userProfile?['weight'] as int? ?? _statsData['weight'];
        final age = userProfile?['age'] as int? ?? _statsData['age'];
        final goal = userProfile?['fitness_goal'] as String? ?? _statsData['goal'];
        final dailyStepTarget = userProfile?['daily_step_target'] as int? ?? 10000;
        final weeklyWorkoutTarget = userProfile?['weekly_workout_target'] as int? ?? 3;
        
        // Load workout history for the user
        final workoutHistory = await authService.getWorkoutHistory();
        
        // Calculate total calories burned and workouts completed
        int totalCaloriesBurned = 0;
        int workoutsCompleted = workoutHistory.length;
        
        for (final workout in workoutHistory) {
          totalCaloriesBurned += (workout['calories_burned'] as int? ?? 0);
        }
        
        // Load step history for streak calculation
        final now = DateTime.now();
        final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
        final stepHistory = await authService.getStepHistory(
          startDate: oneMonthAgo,
          endDate: now,
        );
        
        // Calculate streak days
        int streakDays = 0;
        // This would require more complex logic in a real app
        
        if (mounted) {
          setState(() {
            _statsData = {
              'height': height,
              'weight': weight,
              'age': age,
              'goal': goal,
              'workoutsCompleted': workoutsCompleted,
              'streakDays': streakDays,
              'totalCaloriesBurned': totalCaloriesBurned,
              'dailyStepTarget': dailyStepTarget,
              'weeklyWorkoutTarget': weeklyWorkoutTarget,
            };
          });
        }
      } catch (e) {
        debugPrint('Error loading user stats: $e');
      }
    }
  }

  // Load user achievements
  Future<void> _loadAchievements() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? currentUser = authService.currentUser;
    
    if (currentUser != null) {
      final achievements = await AchievementService.loadAchievements(currentUser.id);
      if (mounted) {
        setState(() {
          _achievements = achievements;
        });
      }
    }
  }

  Color _getBMICategoryColor() {
    if (_bmiCategory == 'Underweight') {
      return Colors.blue;
    } else if (_bmiCategory == 'Normal weight') {
      return Colors.green;
    } else if (_bmiCategory == 'Overweight') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  Widget _buildWeeklyProgressStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  // Add the missing _buildStatItem method
  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Show image picker options (camera or gallery)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GlassContainer(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(source: 'camera');
                      },
                    ),
                    _buildImagePickerOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(source: 'gallery');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Build image picker option button
  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor, width: 1),
            ),
            child: Icon(
              icon,
              size: 30,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Pick image from camera or gallery  
  Future<void> _pickImage({required String source}) async {    
    try {      
      final ImagePicker picker = ImagePicker();      
      final XFile? image = await picker.pickImage(        
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,        
        maxWidth: 1000,        
        maxHeight: 1000,        
        imageQuality: 85,      
      );            
      
      if (image != null) {        
        debugPrint('Image picked: ${image.path}');                
        
        // Get the current auth service and user
        final authService = Provider.of<AuthService>(context, listen: false);        
        final user = authService.currentUser;                
        
        if (user != null) {          
          // Use the actual picked image file path instead of a hardcoded URL
          // In a real app, this would upload to a server and get a URL back
          // For local testing, we can use the file:// URL scheme
          String newPhotoUrl = 'file://${image.path}';
          
          // Update user profile with the new photo URL          
          await authService.updateProfile(photoUrl: newPhotoUrl);                    
          
          // Refresh UI          
          setState(() {});                    
          
          // Show success message          
          if (mounted) {            
            ScaffoldMessenger.of(context).showSnackBar(              
              const SnackBar(content: Text('Profile photo updated')),            
            );          
          }        
        }      
      }    
    } catch (e) {      
      debugPrint('Error picking image: $e');      
      if (mounted) {        
        ScaffoldMessenger.of(context).showSnackBar(          
          SnackBar(content: Text('Error selecting image: $e')),        
        );      
      }    
    }  
  }

  // Helper method to handle different types of image paths
  ImageProvider _getImageProvider(String photoUrl) {
    if (photoUrl.startsWith('file://')) {
      // Remove 'file://' prefix for local files
      String filePath = photoUrl.replaceFirst('file://', '');
      return FileImage(File(filePath));
    } else if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    } else {
      // Assume it's a local file without the file:// prefix
      return FileImage(File(photoUrl));
    }
  }
} 