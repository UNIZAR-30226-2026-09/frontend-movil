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
          onPressed: () => context.push(AppRoutes.batalla),
          child: const Text("Ver Mapa"),
        ),
      ),
    );
  }
}
