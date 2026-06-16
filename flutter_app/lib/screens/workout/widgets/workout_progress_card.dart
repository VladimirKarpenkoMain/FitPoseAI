import 'package:flutter/material.dart';

class WorkoutProgressCard extends StatelessWidget {
  const WorkoutProgressCard({
    super.key,
    required this.title,
    required this.goalText,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryText,
    required this.progressFraction,
  });

  final String title;
  final String goalText;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryText;
  final double progressFraction;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progressFraction.clamp(0.0, 1.0);
    final progressPercent = (clampedProgress * 100).round();

    return Container(
      key: const Key('workout-progress-card-container'),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1F18212F)),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1F18212F),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF18212F),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  primaryLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6C7788),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          primaryValue,
                          style: const TextStyle(
                            color: Color(0xFFFF7A00),
                            fontSize: 76,
                            fontWeight: FontWeight.w900,
                            height: 0.88,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        secondaryText,
                        style: const TextStyle(
                          color: Color(0xFF18212F),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  goalText,
                  style: const TextStyle(
                    color: Color(0xFF6C7788),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: clampedProgress,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0x33FF7A00),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF7A00)),
                ),
                Center(
                  child: Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      color: Color(0xFF18212F),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
