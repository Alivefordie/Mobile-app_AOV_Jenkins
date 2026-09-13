import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterSubmitButton extends StatelessWidget {
  const RegisterSubmitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF20D13),
              disabledBackgroundColor: const Color(0xFFF58A8D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sign Up',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        );
      },
    );
  }
}
