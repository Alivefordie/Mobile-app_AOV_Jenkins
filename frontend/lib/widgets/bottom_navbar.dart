import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_event.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final pageBloc = context.read<PageBloc>();
    final selectedPage = context.watch<PageBloc>().state.selectedPage;

    return BottomNavigationBar(
      currentIndex: selectedPage,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      showUnselectedLabels: true,

      onTap: (index) {
        pageBloc.add(PageChangeEvent(index));
      },

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person_rounded),
          label: "Profile",
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.warning_amber_rounded),
        //   activeIcon: Icon(Icons.warning_rounded),
        //   label: "! ! !",
        // ),
      ],
    );
  }
}
