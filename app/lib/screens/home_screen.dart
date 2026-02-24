import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'About',
            onPressed: () => context.push(AppRoutes.menu),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Center(
        child: Image.asset(
          'assets/images/Logo_Soberania.jpeg',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
      bottomNavigationBar: 
        BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
    );
  }
}
