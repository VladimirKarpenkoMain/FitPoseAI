import 'package:flutter/material.dart';

import 'workout_live_header.dart';

class WorkoutHudOverlay extends StatelessWidget {
  const WorkoutHudOverlay({
    super.key,
    required this.title,
    required this.onBack,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryText,
    required this.goalText,
    required this.systemStatus,
    required this.startGuide,
    required this.liveCue,
    required this.repSummary,
    required this.progressCard,
    required this.statusStack,
    required this.finishButton,
  });

  final String title;
  final VoidCallback onBack;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryText;
  final String goalText;
  final String systemStatus;
  final String startGuide;
  final String liveCue;
  final String repSummary;
  final Widget progressCard;
  final Widget statusStack;
  final Widget finishButton;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.landscape) {
      return _LandscapeWorkoutHud(
        title: title,
        onBack: onBack,
        primaryValue: primaryValue,
        primaryLabel: primaryLabel,
        secondaryText: secondaryText,
        goalText: goalText,
        systemStatus: systemStatus,
        startGuide: startGuide,
        liveCue: liveCue,
        repSummary: repSummary,
        progressCard: progressCard,
        finishButton: finishButton,
      );
    }

    return _PortraitWorkoutHud(
      title: title,
      onBack: onBack,
      progressCard: progressCard,
      statusStack: statusStack,
      finishButton: finishButton,
    );
  }
}

class _PortraitWorkoutHud extends StatelessWidget {
  const _PortraitWorkoutHud({
    required this.title,
    required this.onBack,
    required this.progressCard,
    required this.statusStack,
    required this.finishButton,
  });

  final String title;
  final VoidCallback onBack;
  final Widget progressCard;
  final Widget statusStack;
  final Widget finishButton;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        WorkoutLiveHeader(title: title, onBack: onBack),
        Positioned(
          key: const Key('workout-hud-portrait-progress'),
          top: size.height * 0.115,
          left: 16,
          right: 16,
          child: progressCard,
        ),
        Positioned(
          key: const Key('workout-hud-portrait-status'),
          left: 16,
          right: 16,
          bottom: 110,
          child: statusStack,
        ),
        Positioned(
          key: const Key('workout-hud-portrait-finish'),
          left: 16,
          right: 16,
          bottom: 24,
          child: finishButton,
        ),
      ],
    );
  }
}

class _LandscapeWorkoutHud extends StatelessWidget {
  const _LandscapeWorkoutHud({
    required this.title,
    required this.onBack,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryText,
    required this.goalText,
    required this.systemStatus,
    required this.startGuide,
    required this.liveCue,
    required this.repSummary,
    required this.progressCard,
    required this.finishButton,
  });

  final String title;
  final VoidCallback onBack;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryText;
  final String goalText;
  final String systemStatus;
  final String startGuide;
  final String liveCue;
  final String repSummary;
  final Widget progressCard;
  final Widget finishButton;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final height = MediaQuery.sizeOf(context).height;
    final bottomInset = padding.bottom + 16;
    final sideInset = 16 + padding.left;
    final actionInset = 16 + padding.right;
    final panelWidth = height < 420 ? 250.0 : 300.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        WorkoutLiveHeader(title: title, onBack: onBack),
        Positioned(
          key: const Key('workout-hud-landscape-progress'),
          left: sideInset,
          top: padding.top + 64,
          width: panelWidth,
          child: _LandscapeCounterPanel(
            primaryValue: primaryValue,
            primaryLabel: primaryLabel,
            secondaryText: secondaryText,
            goalText: goalText,
          ),
        ),
        Positioned(
          key: const Key('workout-hud-landscape-status'),
          left: sideInset,
          bottom: bottomInset,
          width: 320,
          child: _LandscapeStatusPanel(
            systemStatus: systemStatus,
            startGuide: startGuide,
            liveCue: liveCue,
            repSummary: repSummary,
          ),
        ),
        Positioned(
          key: const Key('workout-hud-landscape-finish'),
          right: actionInset,
          bottom: bottomInset,
          width: 220,
          child: finishButton,
        ),
      ],
    );
  }
}

class _LandscapeCounterPanel extends StatelessWidget {
  const _LandscapeCounterPanel({
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryText,
    required this.goalText,
  });

  final String primaryValue;
  final String primaryLabel;
  final String secondaryText;
  final String goalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workout-hud-landscape-counter'),
      height: 92,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1F18212F)),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1F18212F),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              primaryValue,
              style: const TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 54,
                fontWeight: FontWeight.w900,
                height: 0.9,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF18212F),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6C7788),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  goalText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6C7788),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _LandscapeStatusPanel extends StatelessWidget {
  const _LandscapeStatusPanel({
    required this.systemStatus,
    required this.startGuide,
    required this.liveCue,
    required this.repSummary,
  });

  final String systemStatus;
  final String startGuide;
  final String liveCue;
  final String repSummary;

  @override
  Widget build(BuildContext context) {
    final visibleLines = [
      systemStatus,
      liveCue,
      repSummary,
      startGuide,
    ].where((line) => line.trim().isNotEmpty).take(2).toList();

    if (visibleLines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('workout-hud-landscape-readable-status'),
      constraints: const BoxConstraints(minHeight: 58, maxHeight: 92),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < visibleLines.length; index++) ...[
            if (index > 0) const SizedBox(height: 5),
            Text(
              visibleLines[index],
              maxLines: index == 0 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: index == 0
                    ? const Color(0xFF18212F)
                    : const Color(0xFF6C7788),
                fontSize: index == 0 ? 14 : 12,
                fontWeight: index == 0 ? FontWeight.w900 : FontWeight.w700,
                height: 1.12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
