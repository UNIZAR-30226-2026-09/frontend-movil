import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_close_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/jugador_partida_model.dart';
import '../models/partida_publica_model.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';

class PartidaRapidaPanel extends ConsumerStatefulWidget {
  const PartidaRapidaPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PartidaRapidaPanel> createState() => _PartidaRapidaPanelState();
}

class _PartidaRapidaPanelState extends ConsumerState<PartidaRapidaPanel> {
  String _status = 'Buscando una partida pública disponible...';
  bool _isResolving = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_resolverPartidaRapida);
  }

  Future<void> _resolverPartidaRapida() async {
    setState(() {
      _isResolving = true;
      _status = 'Buscando una partida pública disponible...';
    });

    try {
      final service = ref.read(matchmakingServiceProvider);
      final partidasPublicas = await service.getPublicMatches();
      final partidasDisponibles = _partidasDisponibles(partidasPublicas);

      for (final partida in partidasDisponibles) {
        if (!mounted) return;
        setState(
          () => _status =
              'Partida encontrada. Uniéndote a la sala ${partida.codigoInvitacion}...',
        );
        final joined = await _joinMatch(partida.codigoInvitacion);
        if (joined) return;
      }

      if (!mounted) return;
      setState(
        () => _status = 'No hay partidas públicas. Creando una nueva sala...',
      );
      await _createQuickMatch();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResolving = false;
        _status =
            'No se pudo resolver la partida rápida. Comprueba tu conexión e inténtalo de nuevo.';
      });
    }
  }

  List<PublicMatchModel> _partidasDisponibles(List<PublicMatchModel> partidas) {
    const estadosNoUnibles = <String>{
      'pausada',
      'pausado',
      'finalizada',
      'finalizado',
      'terminada',
      'terminado',
      'cancelada',
      'cancelado',
    };

    return partidas
        .where((partida) {
          final estado = partida.estado.trim().toLowerCase();
          return partida.codigoInvitacion.isNotEmpty &&
              !estadosNoUnibles.contains(estado);
        })
        .toList(growable: false);
  }

  Future<bool> _joinMatch(String codigo) async {
    final joinResponse = await ref
        .read(matchmakingProvider.notifier)
        .joinMatch(codigo);

    if (!mounted) return false;

    if (joinResponse != null && joinResponse.jugadoresEnSala.isNotEmpty) {
      final partidaId = joinResponse.jugadoresEnSala.first.partidaId;

      ref
          .read(lobbyInfoProvider.notifier)
          .setFromJoinResponse(
            partidaId: partidaId,
            creador: joinResponse.creador,
            jugadoresEnSala: joinResponse.jugadoresEnSala,
            codigoInvitacion: codigo,
          );

      widget.onClose();
      context.push(AppRoutes.lobbyPath(partidaId));
      return true;
    }

    return false;
  }

  Future<void> _createQuickMatch() async {
    final match = await ref
        .read(matchmakingProvider.notifier)
        .createMatch(maxPlayers: 4, visibility: 'publica', timerSeconds: 60);

    if (!mounted) return;

    if (match == null) {
      setState(() {
        _isResolving = false;
        _status =
            ref.read(matchmakingProvider).errorMessage ??
            'No se pudo crear una partida rápida.';
      });
      return;
    }

    final usuarioActual = ref.read(authProvider).user?.username ?? '';
    ref
        .read(lobbyInfoProvider.notifier)
        .setFromCreatedMatch(
          partidaId: match.id,
          creador: usuarioActual,
          codigoInvitacion: match.codigoInvitacion,
          maxPlayers: match.configMaxPlayers,
          visibility: match.configVisibility,
          timerSeconds: match.configTimerSeconds,
          jugadoresEnSala: [
            JugadorPartidaModel(
              usuarioId: usuarioActual,
              partidaId: match.id,
              turno: 0,
              estadoJugador: 'vivo',
            ),
          ],
        );

    widget.onClose();
    context.push(AppRoutes.lobbyPath(match.id));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 280),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panelOverlay.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderGold, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PARTIDA RÁPIDA',
                      style: TextStyle(
                        color: AppTheme.borderGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppCloseButton(onPressed: widget.onClose),
                ],
              ),
              const Spacer(),
              Icon(
                _isResolving
                    ? Icons.travel_explore_rounded
                    : Icons.error_outline_rounded,
                color: AppTheme.borderGold,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (_isResolving) ...[
                const SizedBox(height: 18),
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.borderGold),
                ),
              ] else ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _resolverPartidaRapida,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
