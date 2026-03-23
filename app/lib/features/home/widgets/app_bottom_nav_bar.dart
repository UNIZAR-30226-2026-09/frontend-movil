import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.push(AppRoutes.home);
        break;
      case 1:
        context.push(AppRoutes.social);
        break;
      case 2:
        context.push(AppRoutes.lobbyPath(1));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Social',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.gamepad_rounded),
          label: 'Batalla',
        ),
      ],
    );
  }
}