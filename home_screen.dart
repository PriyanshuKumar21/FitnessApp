import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import '../services/step_counter_service.dart';
import '../models/workout_data.dart';
import 'workout_detail_screen.dart';
import 'dart:math' as math;
import '../services/custom_workout_service.dart';
import '../models/custom_workout_model.dart';
import 'package:provider/provider.dart';
import '../widgets/glowing_icon_button.dart';
import '../widgets/cyber_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _steps = 0;
  int _stepsTarget = 10000;
  String _formattedTime = '00:00:00';
  bool _isStepCounting = false;
  bool _isTimerRunning = false;
  late AnimationController _animationController;
  
  // Timer variables
  Timer? _timer;
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  
  // Step counter service
  final StepCounterService _stepCounterService = StepCounterService();

  final List<Map<String, dynamic>> _workoutSuggestions = [
    WorkoutData.cardioWorkouts[0], // Running
    WorkoutData.strengthWorkouts[0], // Upper Body Strength
    WorkoutData.cardioWorkouts[4], // HIIT Cardio
  ];

  // Featured workouts for the workout list section
  final List<Map<String, dynamic>> _featuredWorkouts = [
    {
      'name': 'Full Body HIIT',
      'description': 'High intensity interval training to burn calories and improve cardiovascular health.',
      'type': 'HIIT',
      'duration': '30 min',
      'calories': 350,
      'difficulty': 'Hard',
      'color': Colors.orange,
      'icon': FontAwesomeIcons.bolt,
    },
    {
      'name': 'Core Crusher',
      'description': 'Focus on your abs, obliques and lower back for a strong core.',
      'type': 'Strength',
      'duration': '20 min',
      'calories': 180,
      'difficulty': 'Medium',
      'color': Colors.red,
      'icon': FontAwesomeIcons.dumbbell,
    },
    {
      'name': 'Morning Yoga Flow',
      'description': 'Start your day with energizing yoga poses to improve flexibility and focus.',
      'type': 'Yoga',
      'duration': '25 min',
      'calories': 120,
      'difficulty': 'Easy',
      'color': Colors.purple,
      'icon': FontAwesomeIcons.handsPraying,
    },
    {
      'name': '5K Run',
      'description': 'Structured running workout to help you prepare for a 5K race.',
      'type': 'Cardio',
      'duration': '45 min',
      'calories': 450,
      'difficulty': 'Medium',
      'color': Colors.blue,
      'icon': FontAwesomeIcons.personRunning,
    },
  ];

  late CustomWorkoutService _customWorkoutService;
  List<CustomWorkout> _customWorkouts = [];
  bool _loadingCustomWorkouts = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Initialize step counter service
    _stepCounterService.addListener(_updateStepCount);
    
    // Initialize custom workout service
    _customWorkoutService = Provider.of<CustomWorkoutService>(context, listen: false);
    _loadCustomWorkouts();
  }

  void _updateStepCount() {
    if (mounted) {
      setState(() {
        _steps = _stepCounterService.steps;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _stepCounterService.removeListener(_updateStepCount);
    _stepCounterService.stopCounting();
    super.dispose();
  }
  
  // Start or stop step counting
  void _toggleStepCounting() {
    setState(() {
      _isStepCounting = !_isStepCounting;
      if (_isStepCounting) {
        _stepCounterService.startCounting();
      } else {
        _stepCounterService.stopCounting();
      }
    });
  }
  
  // Start or stop workout timer
  void _toggleWorkoutTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
      if (_isTimerRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }
  
  // Start timer functionality
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds == 60) {
          _seconds = 0;
          _minutes++;
          if (_minutes == 60) {
            _minutes = 0;
            _hours++;
          }
        }
        _formattedTime = _formatTime(_hours, _minutes, _seconds);
      });
    });
  }
  
  // Stop timer functionality
  void _stopTimer() {
    _timer?.cancel();
  }
  
  // Reset timer functionality
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _seconds = 0;
      _minutes = 0;
      _hours = 0;
      _formattedTime = _formatTime(_hours, _minutes, _seconds);
    });
  }
  
  // Format time as HH:MM:SS
  String _formatTime(int hours, int minutes, int seconds) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Reset step counter
  void _resetSteps() {
    setState(() {
      _steps = 0;
      _stepCounterService.resetSteps();
    });
  }

  // Load custom workouts
  Future<void> _loadCustomWorkouts() async {
    setState(() {
      _loadingCustomWorkouts = true;
    });
    
    await _customWorkoutService.loadCustomWorkouts();
    
    setState(() {
      _customWorkouts = _customWorkoutService.customWorkouts;
      _loadingCustomWorkouts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildProgressSection(),
              const SizedBox(height: 24),
              _buildWeeklyReportSection(),
              const SizedBox(height: 24),
              _buildWorkoutSuggestions(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildWorkoutList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Steps Today',
            _steps.toString(),
            Icons.directions_walk,
            _isStepCounting,
            _toggleStepCounting,
            onReset: _resetSteps,
            isStep: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Workout Timer',
            _formattedTime,
            Icons.timer,
            _isTimerRunning,
            _toggleWorkoutTimer,
            onReset: _resetTimer,
            isStep: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    bool isActive,
    VoidCallback onToggle, {
    VoidCallback? onReset,
    bool isStep = false,
  }) {
    // Calculate steps progress percentage for steps card
    double stepsProgress = isStep ? _steps / _stepsTarget : 0.0;
    stepsProgress = stepsProgress.clamp(0.0, 1.0);
    
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      addShimmer: isActive,
      borderColor: isActive 
          ? (isStep ? AppTheme.primaryColor : Colors.red).withOpacity(0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  if (onReset != null)
                    InkWell(
                      onTap: onReset,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: isActive 
                              ? (isStep ? AppTheme.primaryColor : Colors.red)
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 20,
                    color: isActive 
                        ? (isStep ? AppTheme.primaryColor : Colors.red)
                        : AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isStep) ...[
            const SizedBox(height: 4),
            Text(
              '${(_steps / _stepsTarget * 100).toInt()}% of daily goal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
          const SizedBox(height: 12),
          isStep 
              ? _buildStepsProgress(stepsProgress)
              : AnimatedGlowButton(
                  text: isActive ? 'Stop' : 'Start',
                  onPressed: onToggle,
                  isActive: isActive,
                  height: 40,
                  color: isActive ? Colors.red : AppTheme.primaryColor,
                  textColor: Colors.black,
                  icon: isActive ? Icons.stop : Icons.play_arrow,
                ),
        ],
      ),
    );
  }

  Widget _buildStepsProgress(double progress) {
    final color = AppTheme.primaryColor;
    final progressColor = color.withOpacity(0.8);
    final progressText = '${(_steps / _stepsTarget * 100).toInt()}%';
    
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Progress background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Progress bar
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.7),
                    color,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              // Add subtle shine effect
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CustomPaint(
                  painter: ShinePainter(color: Colors.white.withOpacity(0.2)),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ),
          ),
          // Progress indicator line
          if (progress > 0.02) // Only show the indicator if there's visible progress
            Positioned(
              left: (progress * MediaQuery.of(context).size.width * 0.8).clamp(0, MediaQuery.of(context).size.width - 50),
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 2,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Toggle Button
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _toggleStepCounting,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isStepCounting ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isStepCounting ? 'Pause' : 'Resume',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        progressText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    // Calculate progress percentages based on step counter data
    final stepProgress = _stepCounterService.getDailyGoalProgress();
    final calorieProgress = _steps > 0 ? math.min(1.0, _stepCounterService.caloriesBurned / 500) : 0.0;
    final distanceProgress = _steps > 0 ? math.min(1.0, _stepCounterService.distanceCovered / 5000) : 0.0;
    
    return GlassContainer(
      borderRadius: 16,
      addGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'Daily Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressIndicator('Steps', stepProgress, Colors.blue, '${_steps}/${_stepsTarget}'),
              _buildProgressIndicator('Calories', calorieProgress, Colors.orange, '${_stepCounterService.caloriesBurned.toStringAsFixed(1)} cal'),
              _buildProgressIndicator('Distance', distanceProgress, Colors.cyan, '${(_stepCounterService.distanceCovered / 1000).toStringAsFixed(2)} km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double percent, Color color, String text) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          footer: Text(
            text,
            style: const TextStyle(fontSize: 10),
          ),
          progressColor: color,
          backgroundColor: color.withOpacity(0.2),
          animation: true,
          animationDuration: 1500,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Workouts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
            ),
            const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _workoutSuggestions.length,
            itemBuilder: (context, index) {
              final workout = _workoutSuggestions[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: GlowingContainer(
                  glowColor: workout['color'],
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  animate: index == 0, // Animate the first card
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: workout['color'].withOpacity(0.2),
                            radius: 16,
                            child: FaIcon(
                              workout['icon'],
                              color: workout['color'],
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              workout['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        workout['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            workout['duration'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[300],
                            ),
                          ),
                          NeuButton(
                            text: 'START',
                            width: 80,
                            height: 36,
                            onPressed: () {
                              // Navigate to workout detail screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkoutDetailScreen(workout: workout),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              context,
              'Start Workout',
              Icons.fitness_center,
              () {
                // Navigate to the first workout in suggestions
                if (_workoutSuggestions.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(workout: _workoutSuggestions[0]),
                    ),
                  );
                }
              },
            ),
            _buildQuickActionCard(
              context,
              'Custom Workout',
              Icons.add_task,
              () {
                _showCustomWorkoutDialog();
              },
            ),
            _buildQuickActionCard(
              context,
              'Reset Stats',
              Icons.refresh,
              () {
                // Reset all stats
                _resetSteps();
                _resetTimer();
                setState(() {});
              },
            ),
            _buildQuickActionCard(
              context,
              'Track Steps',
              Icons.directions_walk,
              () {
                // Toggle step counting
                _toggleStepCounting();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GlassCard(
      borderRadius: 16,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show custom workout dialog
  void _showCustomWorkoutDialog() {
    String workoutName = 'Custom Workout';
    int durationMinutes = 20;
    String workoutType = 'Strength';
    int calories = 200;
    String difficulty = 'Medium';
    
    final workoutTypes = ['Strength', 'Cardio', 'Yoga', 'HIIT', 'Stretching'];
    final difficultyLevels = ['Easy', 'Medium', 'Hard'];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Create Custom Workout'),
              content: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Workout Name',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      workoutName = value.isNotEmpty ? value : 'Custom Workout';
                    },
                    controller: TextEditingController(text: workoutName),
                  ),
                  const SizedBox(height: 16),
                  
                  // Workout type dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Workout Type',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[800],
                    value: workoutType,
                      items: workoutTypes
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                              ))
                          .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          workoutType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                    // Duration slider
                    Text('Duration: $durationMinutes minutes',
                        style: const TextStyle(color: Colors.white)),
                    Slider(
                          value: durationMinutes.toDouble(),
                          min: 5,
                      max: 120,
                      divisions: 23,
                          activeColor: AppTheme.primaryColor,
                      inactiveColor: Colors.grey[700],
                          onChanged: (value) {
                            setState(() {
                              durationMinutes = value.toInt();
                            });
                          },
                        ),
                    const SizedBox(height: 16),
                    
                    // Calories slider
                    Text('Calories: $calories',
                        style: const TextStyle(color: Colors.white)),
                    Slider(
                      value: calories.toDouble(),
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      activeColor: AppTheme.primaryColor,
                      inactiveColor: Colors.grey[700],
                      onChanged: (value) {
                        setState(() {
                          calories = value.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Difficulty dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[800],
                      value: difficulty,
                      items: difficultyLevels
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            difficulty = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                AnimatedGlowButton(
                  text: 'Create',
                  onPressed: () async {
                    // Create a custom workout
                    final customWorkout = {
                      'name': workoutName,
                      'type': workoutType,
                      'duration': '$durationMinutes min',
                      'description': 'A custom $workoutType workout',
                      'color': _getColorForWorkoutType(workoutType),
                      'icon': _getIconForWorkoutType(workoutType),
                      'exercises': _getExercisesForType(workoutType),
                      'calories': calories,
                      'difficulty': difficulty,
                    };
                    
                    // Add to database
                    await _customWorkoutService.addCustomWorkout(
                      name: workoutName,
                      type: workoutType,
                      description: 'A custom $workoutType workout',
                      duration: '$durationMinutes min',
                      calories: calories,
                      difficulty: difficulty,
                      color: _getColorForWorkoutType(workoutType),
                      icon: _getIconForWorkoutType(workoutType),
                      exercises: _getExercisesForType(workoutType),
                    );
                    
                    // Reload custom workouts
                    _loadCustomWorkouts();
                    
                    Navigator.of(context).pop();
                    
                    // Navigate to workout detail screen with custom workout
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(workout: customWorkout),
                      ),
                    );
                  },
                  color: AppTheme.primaryColor,
                  textColor: Colors.black,
                  width: 100,
                  height: 40,
                  addCloudyHover: false,
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Helper method to get color for workout type
  Color _getColorForWorkoutType(String type) {
    switch (type) {
      case 'Strength':
        return Colors.red;
      case 'Cardio':
        return Colors.blue;
      case 'Yoga':
        return Colors.purple;
      case 'HIIT':
        return Colors.orange;
      case 'Stretching':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }
  
  // Helper method to get icon for workout type
  IconData _getIconForWorkoutType(String type) {
    switch (type) {
      case 'Strength':
        return FontAwesomeIcons.dumbbell;
      case 'Cardio':
        return FontAwesomeIcons.personRunning;
      case 'Yoga':
        return FontAwesomeIcons.handsPraying;
      case 'HIIT':
        return FontAwesomeIcons.bolt;
      case 'Stretching':
        return FontAwesomeIcons.personFalling;
      default:
        return FontAwesomeIcons.heartPulse;
    }
  }
  
  // Helper method to get exercises for workout type
  List<Map<String, dynamic>> _getExercisesForType(String type) {
    switch (type) {
      case 'Strength':
        return [
          {'name': 'Push-ups', 'sets': 3, 'reps': '12-15', 'rest': '60 sec'},
          {'name': 'Squats', 'sets': 3, 'reps': '15', 'rest': '60 sec'},
          {'name': 'Lunges', 'sets': 3, 'reps': '12 each leg', 'rest': '45 sec'},
          {'name': 'Plank', 'sets': 3, 'duration': '45 sec', 'rest': '30 sec'},
        ];
      case 'Cardio':
        return [
          {'name': 'Warm-up Jog', 'duration': '5 min', 'intensity': 'Low'},
          {'name': 'Sprint Interval', 'duration': '30 sec', 'intensity': 'High'},
          {'name': 'Recovery Jog', 'duration': '1 min', 'intensity': 'Medium'},
          {'name': 'Cool Down', 'duration': '5 min', 'intensity': 'Low'},
        ];
      case 'Yoga':
        return [
          {'name': 'Child\'s Pose', 'duration': '2 min', 'intensity': 'Low'},
          {'name': 'Downward Dog', 'duration': '2 min', 'intensity': 'Medium'},
          {'name': 'Warrior Pose', 'duration': '2 min', 'intensity': 'Medium'},
          {'name': 'Tree Pose', 'duration': '2 min', 'intensity': 'Medium'},
        ];
      case 'HIIT':
        return [
          {'name': 'Jumping Jacks', 'duration': '45 sec', 'intensity': 'High'},
          {'name': 'Rest', 'duration': '15 sec', 'intensity': 'Low'},
          {'name': 'Mountain Climbers', 'duration': '45 sec', 'intensity': 'High'},
          {'name': 'Rest', 'duration': '15 sec', 'intensity': 'Low'},
          {'name': 'Burpees', 'duration': '45 sec', 'intensity': 'High'},
        ];
      case 'Stretching':
        return [
          {'name': 'Hamstring Stretch', 'duration': '30 sec', 'intensity': 'Low'},
          {'name': 'Quad Stretch', 'duration': '30 sec', 'intensity': 'Low'},
          {'name': 'Shoulder Stretch', 'duration': '30 sec', 'intensity': 'Low'},
          {'name': 'Calf Stretch', 'duration': '30 sec', 'intensity': 'Low'},
        ];
      default:
        return [
          {'name': 'Exercise 1', 'duration': '5 min', 'intensity': 'Medium'},
          {'name': 'Exercise 2', 'duration': '5 min', 'intensity': 'Medium'},
          {'name': 'Exercise 3', 'duration': '5 min', 'intensity': 'Medium'},
        ];
    }
  }

  Widget _buildWorkoutList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popular Workouts Section
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Workouts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GlowingIconButton(
                icon: Icons.add,
                onPressed: _showCustomWorkoutDialog,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _featuredWorkouts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(workout: workout),
                      ),
                    );
                  },
                  child: CyberCard(
                    width: 280,
                    height: 200,
                    borderColor: AppTheme.accentColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GlowingContainer(
                                glowColor: workout['color'],
                                height: 40,
                                width: 40,
                                borderRadius: 20,
                                padding: EdgeInsets.zero,
                                child: Center(
                                  child: FaIcon(
                                    workout['icon'],
                                    color: workout['color'],
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  workout['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Text(
                              workout['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWorkoutInfoChip(
                                Icons.timer,
                                workout['duration'],
                              ),
                              _buildWorkoutInfoChip(
                                Icons.local_fire_department,
                                '${workout['calories']} cal',
                              ),
                              _buildWorkoutInfoChip(
                                Icons.fitness_center,
                                workout['difficulty'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Custom Workouts Section
        if (_customWorkouts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Custom Workouts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GlowingIconButton(
                  icon: Icons.add,
                  onPressed: _showCustomWorkoutDialog,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        
        if (_loadingCustomWorkouts)
          const Center(child: CircularProgressIndicator())
        else if (_customWorkouts.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _customWorkouts.length,
              itemBuilder: (context, index) {
                final workout = _customWorkouts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailScreen(
                            workout: workout.toWorkoutMap(),
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showDeleteCustomWorkoutDialog(workout);
                    },
                    child: CyberCard(
                      width: 280,
                      height: 200,
                      borderColor: AppTheme.accentColor,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GlowingContainer(
                                      glowColor: workout.color,
                                      height: 40,
                                      width: 40,
                                      borderRadius: 20,
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: FaIcon(
                                          workout.icon,
                                          color: workout.color,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        workout.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  workout.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildWorkoutInfoChip(
                                      Icons.timer,
                                      workout.duration,
                                    ),
                                    _buildWorkoutInfoChip(
                                      Icons.local_fire_department,
                                      '${workout.calories} cal',
                                    ),
                                    _buildWorkoutInfoChip(
                                      Icons.fitness_center,
                                      workout.difficulty,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GlowingIconButton(
                              icon: Icons.delete,
                              onPressed: () => _showDeleteCustomWorkoutDialog(workout),
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Show delete custom workout dialog
  void _showDeleteCustomWorkoutDialog(CustomWorkout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Custom Workout'),
        content: Text('Are you sure you want to delete "${workout.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (workout.id != null) {
                await _customWorkoutService.deleteCustomWorkout(workout.id!);
                // Reload custom workouts
                _loadCustomWorkouts();
                
                // Show confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${workout.name} has been deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // Add weekly report section
  Widget _buildWeeklyReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'This Week\'s Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${DateTime.now().day}/${DateTime.now().month}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CircularPercentIndicator(
                radius: 70.0,
                lineWidth: 12.0,
                percent: 0.7, // Example progress
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '70', // Example percentage
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Text(
                          '%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text('Completed'),
                  ],
                ),
                progressColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                animation: true,
                animationDuration: 1500,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeeklyProgressStat(
                      'Workouts',
                      '7/10',
                      FontAwesomeIcons.dumbbell,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildWeeklyProgressStat(
                      'Calories',
                      '3,500',
                      FontAwesomeIcons.fire,
                      Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildWeeklyProgressStat(
                      'Time',
                      '5h 30m',
                      FontAwesomeIcons.clock,
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildWeeklyProgressStat(
                      'Steps',
                      '45,000',
                      FontAwesomeIcons.personWalking,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
}

// Shine effect painter class
class ShinePainter extends CustomPainter {
  final Color color;
  
  ShinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CloudyEffectPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  
  CloudyEffectPainter({
    required this.color,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency
    final numClouds = 5;
    
    for (int i = 0; i < numClouds; i++) {
      final offsetX = random.nextDouble() * size.width;
      final offsetY = random.nextDouble() * size.height;
      final radius = size.width * 0.1 * (0.5 + random.nextDouble());
      
      // Calculate oscillating opacity based on animation value and cloud index
      final phase = (i / numClouds) * 2 * math.pi;
      final opacity = 0.1 + 0.1 * math.sin(animationValue * 2 * math.pi + phase);
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
      canvas.drawCircle(Offset(offsetX, offsetY), radius, paint);
    }
    
    // Add a subtle glow around the card edges
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(16));
    
    canvas.drawRRect(rRect, glowPaint);
  }
  
  @override
  bool shouldRepaint(CloudyEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 