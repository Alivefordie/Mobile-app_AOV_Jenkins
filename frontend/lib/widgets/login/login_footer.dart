import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(color: Color(0xFF8A8A8A)),
            children: [
              TextSpan(
                text: 'Sign Up',
                style: TextStyle(
                  color: Color(0xFFF20D13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
