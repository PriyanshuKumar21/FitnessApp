import 'package:flutter/foundation.dart';
import 'dart:async';

class WorkoutTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  Duration _workoutDuration = const Duration(minutes: 30);

  Duration get elapsed => _elapsed;
  bool get isRunning => _isRunning;
  Duration get workoutDuration => _workoutDuration;

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsed += const Duration(seconds: 1);
        notifyListeners();
      });
    }
  }

  void pauseTimer() {
    if (_isRunning) {
      _isRunning = false;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void setWorkoutDuration(Duration duration) {
    _workoutDuration = duration;
    notifyListeners();
  }

  String get formattedTime {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_elapsed.inHours);
    final minutes = twoDigits(_elapsed.inMinutes.remainder(60));
    final seconds = twoDigits(_elapsed.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 