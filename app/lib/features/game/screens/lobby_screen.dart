import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/home/widgets/app_bottom_nav_bar.dart';
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
              child: const Text('IR AL MAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),

      // BOTÓN TEMPORAL PARA DESBLOQUEAR EL PASO AL MAPA
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          // Inyectamos un estado fake completo con tropas repartidas entre nick y pepe
          // para poder probar el flujo de ataque sin depender del backend de inicio de partida.
          // Cuando el backend empuje PARTIDA_INICIADA con el mapa real, esto se sobreescribirá solo.
          const fakeJsonString = '''
          {
            "fase_actual": "ataque_convencional",
            "turno_actual": "nick",
            "jugadores": {
              "nick": {"tropas_reserva": 5},
              "pepe": {"tropas_reserva": 3}
            },
            "mapa": {
              "hoya_de_huesca": {"owner_id": "nick", "units": 8},
              "alto_gallego": {"owner_id": "nick", "units": 6},
              "la_jacetania": {"owner_id": "nick", "units": 4},
              "sobrarbe": {"owner_id": "nick", "units": 5},
              "la_ribagorza": {"owner_id": "nick", "units": 3},
              "monegros": {"owner_id": "pepe", "units": 7},
              "bajo_aragon_caspe": {"owner_id": "pepe", "units": 4},
              "zaragoza": {"owner_id": "pepe", "units": 9},
              "ribera_alta_del_ebro": {"owner_id": "pepe", "units": 3},
              "campo_de_zaragoza": {"owner_id": "pepe", "units": 5}
            }
          }
          ''';
          final fakeJson = jsonDecode(fakeJsonString);
          ref.read(gameProvider.notifier).actualizarDesdeServidor(fakeJson);
        },
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }
}