import 'package:flutter/material.dart';

class SkillBadge extends StatelessWidget {
  const SkillBadge({super.key, required this.skillName, required this.color});

  final String skillName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        skillName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
        ),
      ),
    );
  }
}
