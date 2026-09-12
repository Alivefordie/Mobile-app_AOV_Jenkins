import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocBuilder<PageBloc, PageState>(
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
    );
  }
}
