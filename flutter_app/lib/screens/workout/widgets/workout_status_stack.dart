import 'package:flutter/material.dart';

class WorkoutStatusStack extends StatelessWidget {
  const WorkoutStatusStack({
    super.key,
    required this.systemStatus,
    required this.liveCue,
    required this.repSummary,
    this.startGuide = '',
  });

  final String systemStatus;
  final String liveCue;
  final String repSummary;
  final String startGuide;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('System status', systemStatus),
      ('Start guide', startGuide),
      ('Live cue', liveCue),
      ('Last rep', repSummary),
    ].where((item) => item.$2.isNotEmpty).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = items.first;
    final secondary = items.skip(1).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusLine(
            label: primary.$1,
            value: primary.$2,
            prominent: true,
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in secondary)
                  _StatusChip(label: item.$1, value: item.$2),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    required this.prominent,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: prominent ? 17 : 14,
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: _StatusLine(
        label: label,
        value: value,
        prominent: false,
      ),
    );
  }
}
