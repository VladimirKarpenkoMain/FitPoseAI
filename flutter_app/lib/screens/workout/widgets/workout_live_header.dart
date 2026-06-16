import 'package:flutter/material.dart';

class WorkoutLiveHeader extends StatelessWidget {
  const WorkoutLiveHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: _HeaderButton(
            onPressed: onBack,
            icon: Icons.arrow_back_rounded,
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.onPressed,
    required this.icon,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1F18212F)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFF18212F)),
        ),
      ),
    );
  }
}
