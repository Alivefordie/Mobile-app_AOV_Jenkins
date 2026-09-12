import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/login/login_social_buttons.dart';
import 'package:flutter_application_1/widgets/register/register_form_fields.dart';
import 'package:flutter_application_1/widgets/login/login_submit_button.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    required this.formKey,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.acceptedTerms,
    required this.onTermsChanged,
    required this.onSubmit,
    required this.onSignIn,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool acceptedTerms;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegisterFormFields(
              displayNameController: displayNameController,
              emailController: emailController,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              obscurePassword: obscurePassword,
              obscureConfirmPassword: obscureConfirmPassword,
              onTogglePassword: onTogglePassword,
              onToggleConfirmPassword: onToggleConfirmPassword,
              onSubmitted: onSubmit,
            ),
            const SizedBox(height: 12),
            _terms(acceptedTerms, onTermsChanged),
            const SizedBox(height: 18),
            LoginSubmitButton(onPressed: onSubmit, label: 'Sign Up'),
            const SizedBox(height: 20),
            const LoginSocialButtons(),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: onSignIn,
                child: const Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: Color(0xFF8A8A8A)),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: Color(0xFFF20D13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _terms(bool accepted, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          activeColor: const Color(0xFFF20D13),
          visualDensity: VisualDensity.compact,
          onChanged: (value) => onChanged(value ?? false),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 7, left: 6),
            child: Text.rich(
              TextSpan(
                text: 'I agree with the ',
                children: [
                  TextSpan(
                    text: 'User Agreement',
                    style: TextStyle(
                      color: Color(0xFFF20D13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFFF20D13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
