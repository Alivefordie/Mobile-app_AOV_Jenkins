import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/login/login_footer.dart';
import 'package:flutter_application_1/widgets/login/login_form_fields.dart';
import 'package:flutter_application_1/widgets/login/login_social_buttons.dart';
import 'package:flutter_application_1/widgets/login/login_submit_button.dart';
import 'package:flutter_application_1/widgets/login/login_terms.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.acceptedTerms,
    required this.onTermsChanged,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool acceptedTerms;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoginFormFields(
              emailController: emailController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              onTogglePassword: onTogglePassword,
              onSubmitted: onSubmit,
            ),
            const SizedBox(height: 2),
            LoginTerms(accepted: acceptedTerms, onChanged: onTermsChanged),
            const SizedBox(height: 20),
            LoginSubmitButton(onPressed: onSubmit),
            const SizedBox(height: 22),
            const LoginSocialButtons(),
            const SizedBox(height: 26),
            const LoginFooter(),
          ],
        ),
      ),
    );
  }
}
