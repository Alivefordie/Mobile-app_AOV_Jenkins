import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_state.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_state.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/home_page.dart';
import 'package:flutter_application_1/views/pages/community_page.dart';
import 'package:flutter_application_1/views/pages/user_page.dart';
import 'package:flutter_application_1/widgets/bottom_navbar.dart';

class MainTreeWidget extends StatefulWidget {
  const MainTreeWidget({super.key, required this.title});

  final String title;

  @override
  State<MainTreeWidget> createState() => _MainTreeWidgetState();
}

class _MainTreeWidgetState extends State<MainTreeWidget> {
  List<Widget> pages = const [HomePage(), CommunityPage(), UserPage()];

  @override
  Widget build(BuildContext context) {
    // ปุ่ม + อยู่บนการ์ดในหน้าลูก จึงฟังผลการเพิ่มของไว้ที่นี่ที่เดียว
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          current.feedback != CartFeedback.none,
      listener: _showCartFeedback,
      child: BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                icon: const Icon(Icons.login_outlined),
                label: const Text('Login'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Register'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: pages.elementAt(state.selectedPage),
          bottomNavigationBar: const BottomNavbar(),
        );
      },
      ),
    );
  }

  void _showCartFeedback(BuildContext context, CartState state) {
    final title = state.feedbackTitle ?? 'เมนูนี้';

    final message = switch (state.feedback) {
      CartFeedback.added => 'เพิ่ม $title ลงตะกร้าแล้ว',
      CartFeedback.alreadyInCart => '$title อยู่ในตะกร้าแล้ว',
      CartFeedback.failed =>
        state.error ?? 'เพิ่ม $title ลงตะกร้าไม่สำเร็จ',
      CartFeedback.none => null,
    };
    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: state.feedback == CartFeedback.failed
              ? Colors.redAccent
              : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
