import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';

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
      ref.read(gameProvider.notifier).resetState();
      ref.read(webSocketProvider.notifier).connectToPartida(widget.partidaId);
    });
  }

  Future<void> _handleLeaveMatch() async {
    final success =
        await ref.read(matchmakingProvider.notifier).leaveMatch(widget.partidaId);

    if (!mounted) return;

    if (success) {
      ref.read(lobbyInfoProvider.notifier).clear();
      ref.read(gameProvider.notifier).resetState();
      ref.read(webSocketProvider.notifier).disconnect();
      context.go(AppRoutes.batallas);
    } else {
      final errorMessage = ref.read(matchmakingProvider).errorMessage ??
          'No se pudo abandonar la partida';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final gameState = ref.watch(gameProvider);
    final wsState = ref.watch(webSocketProvider);
    final lobbyInfo = ref.watch(lobbyInfoProvider);

    final usuarioActual = authState.user?.username;
    //final jugadoresConectados = gameState.jugadores.keys.toList();
    final jugadoresWs = gameState.jugadores.keys.toList();
    final jugadoresIniciales = lobbyInfo.jugadoresEnSala
        .map((j) => j.usuarioId)
        .toList();

    final jugadoresConectados =
        jugadoresWs.isNotEmpty ? jugadoresWs : jugadoresIniciales;
    final creador = lobbyInfo.creador;
    final codigoInvitacion = lobbyInfo.codigoInvitacion;
    final maxJugadores = lobbyInfo.maxPlayers;
    final visibilidad = lobbyInfo.visibility;
    final matchmakingState = ref.watch(matchmakingProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252530),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sala de espera #${widget.partidaId}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: matchmakingState.isLeaving ? null : _handleLeaveMatch,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A24),
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: matchmakingState.isLeaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.logout_rounded, size: 18),
                              label: const Text(
                                'Abandonar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _InfoChip(
                              icon: wsState.isConnected
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              label: wsState.isConnected
                                  ? 'Conectado'
                                  : 'Conectando...',
                              iconColor: wsState.isConnected
                                  ? Colors.green
                                  : Colors.red,                                                              
                            ),
                            _InfoChip(
                              icon: Icons.group,
                              label: '${jugadoresConectados.length} jugadores',
                            ),
                            if(maxJugadores != null)
                              _InfoChip(
                                icon: Icons.groups_2,
                                label: 'Máximo: $maxJugadores',
                              ),
                            if (codigoInvitacion != null)
                              _InfoChip(
                                icon: Icons.key,
                                label: 'Código: $codigoInvitacion',
                              ),
                            if (visibilidad != null)
                              _InfoChip(
                                icon: Icons.public,
                                label: 'Visibilidad: $visibilidad',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Jugadores en la sala',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFA0A0B0)
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: jugadoresConectados.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF252530),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF8C6D3F),
                                  width: 1,
                                ),
                              ),
                            child: const Center(
                              child: Text(
                                'Esperando Jugadores...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFA0A0B0),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252530),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF8C6D3F),
                                width: 1,
                              ),
                            ),
                            child: ListView.separated(
                              itemCount: jugadoresConectados.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final nombreJugador = jugadoresConectados[index];
                                final isCurrentUser = nombreJugador == usuarioActual;
                                final isCreator = nombreJugador == creador;
                                final playerState = gameState.jugadores[nombreJugador];

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A24),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isCurrentUser
                                          ? const Color(0xFFC5A059)
                                          : const Color(0xFF8C6D3F),
                                      width: isCurrentUser ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            const Color(0xFF252530),
                                        child: Icon(
                                          Icons.person,
                                          color: isCurrentUser
                                              ? const Color(0xFFC5A059)
                                              : const Color(0xFFF0F0F5),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombreJugador,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                if (isCurrentUser)
                                                  _MiniTag(
                                                    text: 'Tú',
                                                    backgroundColor:
                                                        const Color(0xFFC5A059),
                                                    textColor:
                                                        const Color(0xFF1A1A24),
                                                  ),
                                                if (isCreator)
                                                  const _MiniTag(
                                                    text: 'Creador',
                                                    backgroundColor:
                                                        Colors.blueGrey,
                                                    textColor: Colors.white,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tropas reserva: ${playerState?.tropasReserva ?? 0}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFFA0A0B0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),                                      
                                    ],
                                  ),
                                );
                              },    
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: jugadoresConectados.isNotEmpty
                        ? () => context.push(AppRoutes.batalla)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'IR AL MAPA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),


      /*body: Padding(
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
      */

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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8C6D3F),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFA0A0B0),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}