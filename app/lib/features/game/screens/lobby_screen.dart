import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../providers/game_provider.dart';
import '../providers/websocket_provider.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final int partidaId;

  const LobbyScreen({super.key, required this.partidaId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(webSocketProvider.notifier).connectToPartida(widget.partidaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final wsState = ref.watch(webSocketProvider);
    final jugadoresConectados = gameState.jugadores.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala de Espera #${widget.partidaId}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: wsState.isConnected ? Colors.green.shade100 : Colors.red.shade100,
              child: Row(
                children: [
                  Icon(
                    wsState.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: wsState.isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    wsState.isConnected ? 'Conectado al servidor' : 'Conectando...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Jugadores en la sala:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: jugadoresConectados.isEmpty
                  ? const Center(child: Text('Esperando jugadores...'))
                  : ListView.builder(
                      itemCount: jugadoresConectados.length,
                      itemBuilder: (context, index) {
                        final nombreJugador = jugadoresConectados[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(nombreJugador),
                            trailing: gameState.turnoDe == nombreJugador 
                                ? const Icon(Icons.star, color: Colors.amber) 
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            ElevatedButton(
              onPressed: jugadoresConectados.isNotEmpty 
                  ? () => context.push(AppRoutes.batalla) 
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('IR AL MAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}