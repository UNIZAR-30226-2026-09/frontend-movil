import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/api/dio_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final int partidaId;
  // Cuando se llega desde el panel de partidas pausadas ya sabemos el estado.
  final bool esPausada;

  const LobbyScreen({
    super.key,
    required this.partidaId,
    this.esPausada = false,
  });

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
    try {
      await ref.read(matchmakingServiceProvider).leaveMatch(widget.partidaId);
      if (!mounted) return;
      ref.read(lobbyInfoProvider.notifier).clear();
      ref.read(gameProvider.notifier).resetState();
      ref.read(webSocketProvider.notifier).disconnect();
      context.go(AppRoutes.batallas);
    } on DioException catch (e) {
      if (!mounted) return;
      final detalle = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? e.message ?? 'No se pudo abandonar')
          : (e.message ?? 'No se pudo abandonar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detalle)),
      );
    }
  }

  Future<void> _handleIniciarPartida() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/partidas/${widget.partidaId}/empezar');

      if (!mounted) return;
      context.go(AppRoutes.batalla);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar: ${e.response?.data}')),
      );
    }
  }

  Future<void> _handleReanudarPartida() async {
    final codigo = ref.read(lobbyInfoProvider).codigoInvitacion;
    if (codigo == null || codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el código de la partida.')),
      );
      return;
    }

    try {
      await ref.read(matchmakingServiceProvider).reanudarPartida(codigo);
      // La navegación de todos los jugadores la dispara PARTIDA_REANUDADA por WS.
    } on DioException catch (e) {
      if (!mounted) return;
      final detalle = (e.response?.data is Map<String, dynamic>)
          ? (e.response?.data['detail']?.toString() ?? e.message ?? 'Error al reanudar')
          : (e.message ?? 'Error al reanudar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detalle)),
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
    final jugadoresWs = gameState.jugadores.keys.toList();
    final jugadoresIniciales = lobbyInfo.jugadoresEnSala
        .map((j) => j.usuarioId)
        .toList();

    // Fusionamos ambas fuentes — los iniciales (HTTP) más los que lleguen por WS.
    // Sin esto, cuando llega NUEVO_JUGADOR solo aparece el recién unido y desaparece el creador.
    final jugadoresConectados = {
      ...jugadoresIniciales,
      ...jugadoresWs,
    }.toList();
    final avataresLobby = {
      for (final jugador in lobbyInfo.jugadoresEnSala)
        jugador.usuarioId: jugador.avatar,
    };
    final creador = lobbyInfo.creador;
    final codigoInvitacion = lobbyInfo.codigoInvitacion;
    final maxJugadores = lobbyInfo.maxPlayers;
    final visibilidad = lobbyInfo.visibility;
    final esCreador = usuarioActual == creador;
    final esPartidaPausada = widget.esPausada;

    // Para la reanudación exigimos que todos los jugadores que entraron
    // por HTTP (los que estaban en la partida original) estén reconectados
    // al WS. Sin esto, el host podría reanudar con jugadores desconectados.
    final todosReconectados = esPartidaPausada &&
        jugadoresIniciales.isNotEmpty &&
        jugadoresIniciales.every((j) => jugadoresWs.contains(j));

    // Escuchamos los eventos de sistema del WS para navegar al momento exacto:
    // PARTIDA_INICIADA    → partida normal arrancada por el host.
    // PARTIDA_REANUDADA   → partida pausada reanudada por el host.
    // El guard de versión evita disparos duplicados.
    ref.listen<WebSocketState>(webSocketProvider, (previous, next) {
      final prevVersion = previous?.versionEventoSistema ?? 0;
      if (next.versionEventoSistema <= prevVersion) return;

      final tipo = next.tipoEventoSistema;

      if (tipo == 'PARTIDA_INICIADA' && !widget.esPausada && mounted) {
        context.go(AppRoutes.batalla);
      }

      if (tipo == 'PARTIDA_REANUDADA' && mounted) {
        context.go(AppRoutes.batalla);
      }
    });

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
                              onPressed: _handleLeaveMatch,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A24),
                                foregroundColor: const Color(0xFFD32F2F),
                                side: const BorderSide(
                                  color: Color(0xFFD32F2F),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
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
                                  ? const Color(0xFF388E3C)
                                  : const Color(0xFFD32F2F),
                            ),
                            _InfoChip(
                              icon: Icons.group,
                              label: '${jugadoresConectados.length} jugadores',
                            ),
                            if (maxJugadores != null)
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
                      color: Color(0xFFA0A0B0),
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
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final nombreJugador =
                                    jugadoresConectados[index];
                                final isCurrentUser =
                                    nombreJugador == usuarioActual;
                                final isCreator = nombreJugador == creador;
                                final playerState =
                                    gameState.jugadores[nombreJugador];
                                final estaOnline =
                                    jugadoresWs.contains(nombreJugador);
                                final avatarJugador = playerState?.avatar ??
                                    avataresLobby[nombreJugador] ??
                                    (isCurrentUser ? authState.user?.avatar : null);

                                return Container(
                                  // Mostrar siempre la tarjeta encendida
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
                                      AppAvatar(
                                        avatar: avatarJugador,
                                        radius: 18,
                                        iconColor: isCurrentUser
                                            ? const Color(0xFFC5A059)
                                            : const Color(0xFFF0F0F5),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                    textColor: const Color(
                                                      0xFF1A1A24,
                                                    ),
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
                  if (esCreador)
                    ElevatedButton(
                      onPressed: esPartidaPausada
                          ? (todosReconectados
                              ? _handleReanudarPartida
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Faltan jugadores por conectarse.',
                                      ),
                                    ),
                                  );
                                })
                          : (jugadoresConectados.length >= 2
                              ? _handleIniciarPartida
                              : null),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: esPartidaPausada
                            ? const Color(0xFF1B5E20)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            esPartidaPausada
                                ? Icons.play_arrow_rounded
                                : Icons.flag_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            esPartidaPausada ? 'REANUDAR PARTIDA' : 'INICIAR PARTIDA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          esPartidaPausada
                              ? 'Esperando a que el creador reanude la partida...'
                              : 'Esperando a que el creador inicie la partida...',
                          style: const TextStyle(color: Color(0xFFA0A0B0)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.iconColor});

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
        border: Border.all(color: const Color(0xFF8C6D3F), width: 1),
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
