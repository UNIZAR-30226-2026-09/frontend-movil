import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importante para poder escuchar los providers
import '../../../app/router/app_routes.dart';
import '../../game/providers/websocket_provider.dart';

// Cambiamos StatelessWidget por ConsumerWidget para que la pantalla pueda usar el "ref" de Riverpod
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  // Al ser ConsumerWidget, el build ahora necesita recibir el WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
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
        // Metemos un Column para poder apilar el botón del mapa y el botón de prueba
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.batalla),
              child: const Text("Ver Mapa"),
            ),
            const SizedBox(height: 30), // Espacio para que no se peguen los botones
            
            // BOTÓN DE PRUEBA WEBSOCKET (T47)
            ElevatedButton(
              onPressed: () {
                // Leemos el provider y lanzamos la conexión a la partida con ID 1
                ref.read(webSocketProvider.notifier).connectToPartida(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, // Lo pinto de verde para no confundirlo
                foregroundColor: Colors.white,
              ),
              child: const Text('🔌 PROBAR WEBSOCKET T47'),
            ),
          ],
        ),
      ),
    );
  }
}