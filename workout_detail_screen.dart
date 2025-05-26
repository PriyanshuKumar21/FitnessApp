import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  // Timer variables
  bool _isTimerRunning = false;
  int _totalSeconds = 0;
  Timer? _timer;
  int _currentExerciseIndex = 0;
  bool _workoutCompleted = false;
  int? _workoutTimerId;

  @override
  void initState() {
    super.initState();
    // Set initial exercise
    if (widget.workout['exercises'] != null &&
        widget.workout['exercises'].isNotEmpty) {
      _currentExerciseIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Cancel workout timer when leaving the screen
    if (_workoutTimerId != null) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.cancelNotification(_workoutTimerId!);
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      
      // Create a workout timer using notification service
      if (_workoutTimerId == null) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        final workoutName = widget.workout['name'];
        // Set a very long duration (we'll manage it manually)
        _workoutTimerId = DateTime.now().millisecondsSinceEpoch;
        notificationService.setWorkoutTimer(workoutName, const Duration(hours: 2));
      }
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _totalSeconds++;
        });
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
      _timer?.cancel();
    });
  }

  void _resetTimer() {
    setState(() {
      _isTimerRunning = false;
      _timer?.cancel();
      _totalSeconds = 0;
      _currentExerciseIndex = 0;
      _workoutCompleted = false;
      
      // Cancel the existing workout timer
      if (_workoutTimerId != null) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.cancelNotification(_workoutTimerId!);
        _workoutTimerId = null;
      }
    });
  }

  void _completeWorkout() {
    setState(() {
      _workoutCompleted = true;
      _pauseTimer();
      
      // Cancel the workout timer
      if (_workoutTimerId != null) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.cancelNotification(_workoutTimerId!);
        
        // Show completion notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.workout['name']} completed! Great job!'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.workout['exercises'].length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _completeWorkout();
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final List exercises = workout['exercises'] ?? [];
    final currentExercise = exercises.isNotEmpty ? exercises[_currentExerciseIndex] : null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 80,
              left: isSmallScreen ? 12.0 : 16.0,
              right: isSmallScreen ? 12.0 : 16.0,
              bottom: isSmallScreen ? 12.0 : 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: workout['color'].withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: workout['color'].withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              workout['icon'],
                              color: workout['color'],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout['name'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  workout['description'] ?? 'No description available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats in a horizontally scrollable row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildWorkoutStat(
                              FontAwesomeIcons.clock,
                              workout['duration'] ?? '0 min',
                            ),
                            const SizedBox(width: 16),
                            _buildWorkoutStat(
                              FontAwesomeIcons.fire,
                              '${workout['calories'] ?? 0} cal',
                            ),
                            const SizedBox(width: 16),
                            _buildWorkoutStat(
                              FontAwesomeIcons.chartLine,
                              workout['difficulty'] ?? 'Medium',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Timer section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Workout Timer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatTime(_totalSeconds),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedGlowButton(
                            text: 'Reset',
                            onPressed: _resetTimer,
                            isActive: false,
                            height: 50,
                            width: isSmallScreen ? 80 : 100,
                            color: Colors.grey,
                            textColor: Colors.white,
                            icon: Icons.refresh,
                          ),
                          const SizedBox(width: 16),
                          AnimatedGlowButton(
                            text: _isTimerRunning ? 'Pause' : 'Start',
                            onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                            isActive: _isTimerRunning,
                            height: 50,
                            width: isSmallScreen ? 80 : 100,
                            color: _isTimerRunning ? Colors.red : AppTheme.primaryColor,
                            textColor: Colors.black,
                            icon: _isTimerRunning ? Icons.pause : Icons.play_arrow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Current exercise section
                if (!_workoutCompleted && currentExercise != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Current Exercise (${_currentExerciseIndex + 1}/${exercises.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getIntensityColor(currentExercise['intensity']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentExercise['intensity'] ?? 'Medium',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentExercise['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (currentExercise['duration'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    'Duration: ${currentExercise['duration']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if (currentExercise['sets'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    'Sets: ${currentExercise['sets']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if (currentExercise['reps'] != null)
                                Text(
                                  'Reps: ${currentExercise['reps']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _previousExercise,
                              icon: const Icon(Icons.arrow_back),
                              color: AppTheme.primaryColor,
                              iconSize: 32,
                              padding: const EdgeInsets.all(12),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _nextExercise,
                              icon: const Icon(Icons.arrow_forward),
                              color: AppTheme.primaryColor,
                              iconSize: 32,
                              padding: const EdgeInsets.all(12),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                // Workout completed
                if (_workoutCompleted)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Workout Completed!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Time: ${_formatTime(_totalSeconds)}',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Calories: ${workout['calories']}',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AnimatedGlowButton(
                          text: 'Restart Workout',
                          onPressed: _resetTimer,
                          isActive: false,
                          height: 50,
                          width: 200,
                          color: AppTheme.primaryColor,
                          textColor: Colors.black,
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // All exercises list
                const Text(
                  'Workout Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _currentExerciseIndex == index
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16, 
                          vertical: 8
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _currentExerciseIndex == index
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              color: _currentExerciseIndex == index
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          exercise['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: exercise['duration'] != null
                            ? Text(
                                'Duration: ${exercise['duration']}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                            : exercise['sets'] != null
                                ? Text(
                                    '${exercise['sets']} sets × ${exercise['reps']} reps',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getIntensityColor(exercise['intensity']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise['intensity'] ?? 'Medium',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _currentExerciseIndex = index;
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Back button in the top-left corner
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          // Title in the top center
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  workout['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Color _getIntensityColor(String? intensity) {
    switch (intensity?.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
      case 'medium-high':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
} 