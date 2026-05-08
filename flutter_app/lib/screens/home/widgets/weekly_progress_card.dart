import 'package:flutter/material.dart';

import '../home_metrics.dart';

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({
    super.key,
    required this.title,
    required this.emptyState,
    required this.sessionsLabel,
    required this.repsLabel,
    required this.qualityLabel,
    required this.summary,
  });

  final String title;
  final String emptyState;
  final String sessionsLabel;
  final String repsLabel;
  final String qualityLabel;
  final WeeklyProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A26), Color(0xFFFF6230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26FF7A00),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 16),
          if (!summary.hasData)
            Text(
              emptyState,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: '${summary.weeklySessions}',
                    label: sessionsLabel,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: '${summary.weeklyReps}',
                    label: repsLabel,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: summary.averageQualityScore == null
                        ? '--'
                        : '${summary.averageQualityScore}/100',
                    label: qualityLabel,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFE0C8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
