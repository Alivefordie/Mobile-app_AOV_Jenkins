import 'package:flutter/material.dart';

class RegisterSocialButtons extends StatelessWidget {
  const RegisterSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'or sign up with',
          style: TextStyle(color: Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            _SocialButton(
              icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.onPressed});

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFE4E4E4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: icon,
      ),
    );
  }
}
