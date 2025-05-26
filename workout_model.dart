class Workout {
  final int? id;
  final String date;
  final int duration;
  final int steps;
  final String type;

  Workout({
    this.id,
    required this.date,
    required this.duration,
    required this.steps,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'duration': duration,
      'steps': steps,
      'type': type,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      date: map['date'],
      duration: map['duration'],
      steps: map['steps'],
      type: map['type'],
    );
  }

  Workout copyWith({
    int? id,
    String? date,
    int? duration,
    int? steps,
    String? type,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      steps: steps ?? this.steps,
      type: type ?? this.type,
    );
  }
}

class DailyStats {
  final int? id;
  final String date;
  final int totalSteps;
  final int totalWorkoutTime;

  DailyStats({
    this.id,
    required this.date,
    required this.totalSteps,
    required this.totalWorkoutTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_steps': totalSteps,
      'total_workout_time': totalWorkoutTime,
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'],
      date: map['date'],
      totalSteps: map['total_steps'],
      totalWorkoutTime: map['total_workout_time'],
    );
  }

  DailyStats copyWith({
    int? id,
    String? date,
    int? totalSteps,
    int? totalWorkoutTime,
  }) {
    return DailyStats(
      id: id ?? this.id,
      date: date ?? this.date,
      totalSteps: totalSteps ?? this.totalSteps,
      totalWorkoutTime: totalWorkoutTime ?? this.totalWorkoutTime,
    );
  }
} 