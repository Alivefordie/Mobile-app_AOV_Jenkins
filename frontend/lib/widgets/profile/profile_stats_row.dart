import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: profile.recipeCount.toString(),
            label: 'Recipes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: profile.savedCount.toString(),
            label: 'Saved',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: profile.rating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ProfileColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
