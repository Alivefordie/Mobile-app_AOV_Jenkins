import 'package:flutter/material.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 9),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('Enter your email address'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 22),
        const _FieldLabel(label: 'Password'),
        const SizedBox(height: 9),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration('Enter your password').copyWith(
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF777777),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          onFieldSubmitted: (_) => onSubmitted(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF777777),
              padding: const EdgeInsets.only(top: 4),
            ),
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      enabledBorder: _border(const Color(0xFFE3E3E3)),
      focusedBorder: _border(const Color(0xFFF20D13), width: 1.5),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.5),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF303030),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
