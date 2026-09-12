import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_state.dart';
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
  List<Widget> pages = const [
    HomePage(),
    CommunityPage(),
    UserPage(),
    //Scaffold(body: Center(child: Text('No route defined'))),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          // appBar: AppBar(
          //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          //   title: Text(widget.title),
          // ),
          body: pages.elementAt(state.selectedPage),
          bottomNavigationBar: const BottomNavbar(),
        );
      },
    );
  }
}
