import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../game/screens/lobby_screen.dart'; // <-- ¡LA PIEZA QUE FALTABA!

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
            tooltip: 'Menú',
            onPressed: () => context.push(AppRoutes.menu),
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => context.push(AppRoutes.ajustes),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LobbyScreen(partidaId: 1)), 
            );
          },
          child: const Text("Entrar al Lobby"),
        ),
      ),
    );
  }
}