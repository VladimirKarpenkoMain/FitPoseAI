import 'package:flutter/material.dart';

class WorkoutProgressCard extends StatelessWidget {
  const WorkoutProgressCard({
    super.key,
    required this.goalText,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryText,
  });

  final String goalText;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(goalText, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            primaryValue,
            style: const TextStyle(
              color: Color(0xFFFFA347),
              fontSize: 88,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            primaryLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(secondaryText, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
