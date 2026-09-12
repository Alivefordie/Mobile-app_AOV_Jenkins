import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfileAccountMenu extends StatelessWidget {
  const ProfileAccountMenu({
    super.key,
    required this.onPressed,
    required this.onSignOut,
  });

  final ValueChanged<String> onPressed;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Personal information',
            onTap: () => onPressed('Personal information'),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            onTap: () => onPressed('Notifications'),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.credit_card_rounded,
            label: 'Payment methods',
            onTap: () => onPressed('Payment methods'),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => onPressed('Help & support'),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            foregroundColor: const Color(0xFFD54444),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor = ProfileColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 58,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: foregroundColor.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foregroundColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: foregroundColor.withValues(alpha: 0.45),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 70, endIndent: 16);
  }
}
