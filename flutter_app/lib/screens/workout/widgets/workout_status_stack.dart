import 'dart:async';

import 'package:flutter/material.dart';

class WorkoutStatusStack extends StatefulWidget {
  const WorkoutStatusStack({
    super.key,
    required this.systemStatus,
    required this.liveCue,
    required this.repSummary,
    this.startGuide = '',
    this.systemStatusLabel = 'System status',
    this.startGuideLabel = 'Start guide',
    this.liveCueLabel = 'Live cue',
    this.repSummaryLabel = 'Last rep',
  });

  final String systemStatus;
  final String liveCue;
  final String repSummary;
  final String startGuide;
  final String systemStatusLabel;
  final String startGuideLabel;
  final String liveCueLabel;
  final String repSummaryLabel;

  @override
  State<WorkoutStatusStack> createState() => _WorkoutStatusStackState();
}

class _WorkoutStatusStackState extends State<WorkoutStatusStack> {
  static const _liveCueHoldDuration = Duration(milliseconds: 1500);

  Timer? _clearLiveCueTimer;
  String _visibleLiveCue = '';

  @override
  void initState() {
    super.initState();
    _syncLiveCue();
  }

  @override
  void didUpdateWidget(covariant WorkoutStatusStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liveCue.isNotEmpty || widget.liveCue != oldWidget.liveCue) {
      _syncLiveCue();
    }
  }

  @override
  void dispose() {
    _clearLiveCueTimer?.cancel();
    super.dispose();
  }

  void _syncLiveCue() {
    final nextCue = widget.liveCue.trim();
    if (nextCue.isEmpty) {
      _scheduleLiveCueClear();
      return;
    }

    _clearLiveCueTimer?.cancel();
    _visibleLiveCue = widget.liveCue;
    _scheduleLiveCueClear();
  }

  void _scheduleLiveCueClear() {
    _clearLiveCueTimer?.cancel();
    if (_visibleLiveCue.isEmpty) {
      return;
    }

    _clearLiveCueTimer = Timer(_liveCueHoldDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleLiveCue = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (widget.systemStatusLabel, widget.systemStatus),
      (widget.startGuideLabel, widget.startGuide),
      (widget.liveCueLabel, _visibleLiveCue),
      (widget.repSummaryLabel, widget.repSummary),
    ].where((item) => item.$2.isNotEmpty).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = items.first;
    final secondary = items.skip(1).toList();

    return Container(
      key: const Key('workout-status-stack-container'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1F18212F)),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1F18212F),
            blurRadius: 22,
            offset: Offset(0, 10),
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
            color: Color(0xFF6C7788),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF18212F),
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
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A18212F)),
      ),
      child: _StatusLine(
        label: label,
        value: value,
        prominent: false,
      ),
    );
  }
}
