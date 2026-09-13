import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/register/register_form.dart';
import 'package:flutter_application_1/widgets/register/register_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // secure storage ไม่มี stream บอกว่า token เปลี่ยน
          // ต้องสั่งให้ตะกร้ากับหัวใจโหลดของคนนี้เองหลัง AuthBloc เขียน token แล้ว
          context.read<CartBloc>().add(const CartRequested());
          context.read<FavoriteBloc>().add(const FavoritesRequested());
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD96868),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const RegisterLogo(),
                RegisterForm(
                  onSubmit:
                      ({
                        required email,
                        required password,
                        required displayName,
                      }) {
                        context.read<AuthBloc>().add(
                          AuthRegisterRequested(
                            email: email,
                            password: password,
                            displayName: displayName,
                          ),
                        );
                      },
                  onSignIn: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
