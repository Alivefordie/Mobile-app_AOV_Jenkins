import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/register/register_form_fields.dart';
import 'package:flutter_application_1/widgets/register/register_social_buttons.dart';
import 'package:flutter_application_1/widgets/register/register_submit_button.dart';
import 'package:flutter_application_1/widgets/register/register_terms.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    required this.onSubmit,
    required this.onSignIn,
    super.key,
  });

  final void Function({
    required String email,
    required String password,
    required String displayName,
  })
  onSubmit;
  final VoidCallback onSignIn;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy policy.'),
        ),
      );
      return;
    }

    widget.onSubmit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );
  }

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
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegisterFormFields(
              displayNameController: _displayNameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              obscurePassword: _obscurePassword,
              obscureConfirmPassword: _obscureConfirmPassword,
              onTogglePassword: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
              onToggleConfirmPassword: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
              onSubmitted: _submit,
            ),
            const SizedBox(height: 12),
            RegisterTerms(
              accepted: _acceptedTerms,
              onChanged: (value) => setState(() {
                _acceptedTerms = value;
              }),
            ),
            const SizedBox(height: 18),
            RegisterSubmitButton(onPressed: _submit),
            const SizedBox(height: 20),
            const RegisterSocialButtons(),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: widget.onSignIn,
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
}
