import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import '../models/workout_data.dart';
import 'workout_detail_screen.dart';

class CardioWorkoutScreen extends StatefulWidget {
  const CardioWorkoutScreen({super.key});

  @override
  State<CardioWorkoutScreen> createState() => _CardioWorkoutScreenState();
}

class _CardioWorkoutScreenState extends State<CardioWorkoutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Use the predefined workouts from our workout data model
  final List<Map<String, dynamic>> _workouts = WorkoutData.cardioWorkouts;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: Column(
          children: [
            // Add top padding to account for the removed header
            const SizedBox(height: 80),
            _buildWeeklyProgressCard(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Cardio Workouts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: _buildWorkoutsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        opaque: true,
        addGlow: true,
        child: Column(
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              radius: 70.0,
              lineWidth: 12.0,
              percent: 0.0, // Reset to 0
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '0', // Reset to 0
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStat(
                  'Workouts',
                  '0/10', // Reset to 0
                  FontAwesomeIcons.dumbbell,
                  Colors.blue,
                ),
                _buildProgressStat(
                  'Calories',
                  '0', // Reset to 0
                  FontAwesomeIcons.fire,
                  Colors.orange,
                ),
                _buildProgressStat(
                  'Time',
                  '0h', // Reset to 0
                  FontAwesomeIcons.clock,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        GlowingContainer(
          glowColor: color,
          height: 40,
          width: 40,
          borderRadius: 20,
          padding: EdgeInsets.zero,
          glowIntensity: 0.3,
          child: Center(
            child: FaIcon(
              icon,
              color: color,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _buildWorkoutsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: workout['color'].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Navigate to workout detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(workout: workout),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leading icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: workout['color'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: FaIcon(
                            workout['icon'],
                            color: workout['color'],
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workout['description'] ?? 'No description available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Wrap the workout details in a Row with Expanded widgets to prevent overflow
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildWorkoutDetailChip(
                                    Icons.timer,
                                    workout['duration'],
                                    Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 1,
                                  child: _buildWorkoutDetailChip(
                                    Icons.local_fire_department,
                                    '${workout['calories']} cal',
                                    Colors.orange.withOpacity(0.2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 1,
                                  child: _buildWorkoutDetailChip(
                                    Icons.fitness_center,
                                    workout['difficulty'] ?? 'Medium',
                                    Colors.purple.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Trailing icon
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutDetailChip(IconData icon, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 