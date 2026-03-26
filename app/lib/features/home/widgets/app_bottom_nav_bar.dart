import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';

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
     return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.primary,
            width: 1.2,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Aliados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad_rounded),
            label: 'Batalla',
          ),
        ],
      ),
    );
  }
}