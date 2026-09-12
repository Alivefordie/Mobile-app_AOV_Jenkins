import 'package:flutter/material.dart';

class RegisterFormFields extends StatelessWidget {
  const RegisterFormFields({
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Display Name'),
        const SizedBox(height: 9),
        TextFormField(
          controller: displayNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _decoration('Enter your display name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your display name';
            }
            if (value.trim().length > 150) {
              return 'Display name must be 150 characters or less';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label('Email Address'),
        const SizedBox(height: 9),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoration('Enter your email address'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!value.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label('Password'),
        const SizedBox(height: 9),
        _passwordField(
          controller: passwordController,
          obscureText: obscurePassword,
          hint: 'Enter your password',
          onToggle: onTogglePassword,
          onSubmitted: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _label('Confirm Password'),
        const SizedBox(height: 9),
        _passwordField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          hint: 'Re-enter your password',
          onToggle: onToggleConfirmPassword,
          onSubmitted: onSubmitted,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF303030),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscureText,
    required String hint,
    required VoidCallback onToggle,
    required VoidCallback? onSubmitted,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      decoration: _decoration(hint).copyWith(
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF777777),
          ),
        ),
      ),
      validator: validator,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
