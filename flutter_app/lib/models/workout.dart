import 'workout_analysis.dart';

class Workout {
  final int id;
  final int userId;
  final String exerciseType;
  final int repCount;
  final DateTime date;
  final int? averageQualityScore;
  final WorkoutAnalysis? analysis;

  Workout({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.repCount,
    required this.date,
    this.averageQualityScore,
    this.analysis,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      userId: json['user_id'],
      exerciseType: json['exercise_type'],
      repCount: json['rep_count'],
      date: DateTime.parse(json['date']),
      averageQualityScore: json['average_quality_score'] as int?,
      analysis: json['analysis'] == null
          ? null
          : WorkoutAnalysis.fromJson(
              Map<String, dynamic>.from(json['analysis'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_type': exerciseType,
      'rep_count': repCount,
      if (averageQualityScore != null) 'average_quality_score': averageQualityScore,
      if (analysis != null) 'analysis': analysis!.toJson(),
    };
  }
}
