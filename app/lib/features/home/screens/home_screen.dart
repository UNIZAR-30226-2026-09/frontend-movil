import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../game/screens/lobby_screen.dart'; 
import '../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.lobbyPath(1));
              },
              child: const Text("Entrar al Lobby"),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton(
                  tooltip: 'Ajustes',
                  onPressed: () {
                    context.push(AppRoutes.ajustes);
                  },
                  icon: const Icon(Icons.settings),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}