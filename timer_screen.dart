import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/workout_timer_service.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Timer'),
      ),
      body: Consumer<WorkoutTimerService>(
        builder: (context, timer, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Workout Duration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  timer.formattedTime,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
                      icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(timer.isRunning ? 'Pause' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: timer.resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildDurationSelector(context, timer),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDurationSelector(BuildContext context, WorkoutTimerService timer) {
    return Column(
      children: [
        const Text(
          'Set Workout Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDurationButton(
              context,
              '15 min',
              const Duration(minutes: 15),
              timer,
            ),
            const SizedBox(width: 8),
            _buildDurationButton(
              context,
              '30 min',
              const Duration(minutes: 30),
              timer,
            ),
            const SizedBox(width: 8),
            _buildDurationButton(
              context,
              '45 min',
              const Duration(minutes: 45),
              timer,
            ),
            const SizedBox(width: 8),
            _buildDurationButton(
              context,
              '60 min',
              const Duration(minutes: 60),
              timer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationButton(
    BuildContext context,
    String label,
    Duration duration,
    WorkoutTimerService timer,
  ) {
    final isSelected = timer.workoutDuration == duration;
    return ElevatedButton(
      onPressed: () => timer.setWorkoutDuration(duration),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }
} 