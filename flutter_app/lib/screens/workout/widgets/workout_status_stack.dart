import 'package:flutter/material.dart';

class WorkoutStatusStack extends StatelessWidget {
  const WorkoutStatusStack({
    super.key,
    required this.systemStatus,
    required this.liveCue,
    required this.repSummary,
  });

  final String systemStatus;
  final String liveCue;
  final String repSummary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('System status', systemStatus),
      ('Live cue', liveCue),
      ('Last rep', repSummary),
    ].where((item) => item.$2.isNotEmpty).toList();

    return Column(
      children: [
        for (final item in items) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.58),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
