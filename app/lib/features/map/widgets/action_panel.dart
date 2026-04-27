import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import '../../../shared/api/dio_provider.dart';
import '../../../app/theme/app_theme.dart';

class ActionPanel extends ConsumerStatefulWidget {
  const ActionPanel({super.key});

  @override
  ConsumerState<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends ConsumerState<ActionPanel> {
  bool _dialogoAtaqueAbierto = false;

  String _formatName(String id) {
    return id
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  ButtonStyle _actionButtonStyle(bool enabled) {
    return ElevatedButton.styleFrom(
      elevation: enabled ? 3 : 0,
      backgroundColor: enabled
          ? const Color(0xFF3A2A16)
          : const Color(0xFF2A241C),
      foregroundColor: enabled
          ? AppTheme.primary
          : AppTheme.textSecondary.withValues(alpha: 0.65),
      disabledBackgroundColor: const Color(0xFF2A241C),
      disabledForegroundColor: AppTheme.textSecondary.withValues(alpha: 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.75)
              : AppTheme.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? '';
    final origenSeleccionado = gameState.origenSeleccionado;
    final esMiTurno = username.isNotEmpty && gameState.turnoDe == username;
    final puedeAtacar = gameState.faseActual == 'ataque_convencional' && esMiTurno;
    final puedeFortificar = gameState.faseActual == 'fortificacion' && esMiTurno;

    ref.listen<GameState>(gameProvider, (previous, next) {
      final destinoAcabaDeSeleccionarse =
          (previous?.destinoSeleccionado == null) && next.destinoSeleccionado != null;

      if (!destinoAcabaDeSeleccionarse || _dialogoAtaqueAbierto) return;

      final origen = next.origenSeleccionado;
      final destino = next.destinoSeleccionado;
      if (origen == null || destino == null) return;

      _dialogoAtaqueAbierto = true;

      // En ataque mostramos confirmación, en fortificación mostramos el slider de tropas
      if (next.faseActual == 'ataque_convencional') {
        _mostrarDialogoAtaque(context, ref, origen, destino)
            .whenComplete(() => _dialogoAtaqueAbierto = false);
      } else if (next.faseActual == 'fortificacion') {
        final tropasOrigen = next.mapa[origen]?.units ?? 0;
        _mostrarDialogoFortificacion(context, ref, origen, destino, tropasOrigen)
            .whenComplete(() => _dialogoAtaqueAbierto = false);
      } else {
        _dialogoAtaqueAbierto = false;
      }
    });

    final bool isVisible = origenSeleccionado != null;
    final territoryData = origenSeleccionado != null ? gameState.mapa[origenSeleccionado] : null;
    final owner = territoryData?.ownerId ?? 'Neutral';
    final units = territoryData?.units ?? 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: isVisible ? 12 : -290,
      top: MediaQuery.of(context).size.height * 0.14,
      width: 270,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        origenSeleccionado != null ? _formatName(origenSeleccionado) : '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        if (origenSeleccionado != null) {
                          ref.read(gameProvider.notifier).seleccionarComarca(
                            origenSeleccionado,
                            jugadorLocalId: username,
                          );
                        }
                      },
                    ),
                  ],
                ),
                Divider(
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  height: 18,
                  thickness: 1,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                owner,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$units',
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (gameState.esperandoDestino) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.ads_click_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                puedeAtacar
                                    ? 'Selecciona un territorio enemigo'
                                    : 'Selecciona un territorio aliado',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          puedeAtacar
                              ? 'Pulsa sobre una comarca adyacente para iniciar el ataque.'
                              : 'Pulsa sobre una comarca válida para mover tropas.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => ref.read(gameProvider.notifier).cancelarAtaque(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text(
                              'Cancelar selección',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.55),
                                width: 1.1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!gameState.esperandoDestino) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: _actionButtonStyle(puedeAtacar),
                        onPressed: puedeAtacar
                            ? () => ref.read(gameProvider.notifier).prepararAtaque()
                            : null,
                        icon: const Icon(Icons.sports_kabaddi_rounded, size: 20),
                        label: const Text(
                          'Atacar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _actionButtonStyle(
                          gameState.faseActual == 'refuerzo' &&
                              esMiTurno &&
                              origenSeleccionado != null,
                        ),
                        onPressed: gameState.faseActual == 'refuerzo' && esMiTurno && origenSeleccionado != null
                            ? () => _mostrarDialogoRefuerzo(context, ref, origenSeleccionado)
                            : null,
                        icon: const Icon(Icons.add_box_rounded, size: 20),
                        label: const Text(
                          'Reforzar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _actionButtonStyle(puedeFortificar && origenSeleccionado != null && units > 1),
                        onPressed: puedeFortificar && origenSeleccionado != null && units > 1
                            ? () => ref.read(gameProvider.notifier).prepararAtaque()
                            : null,
                        icon: const Icon(Icons.fort_rounded, size: 20),
                        label: const Text(
                          'Mover',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),  
    );
  }

  // --- DIÁLOGO DE ATAQUE — ahora es solo una confirmación, sin slider ---
  // El backend resuelve el combate completo (all-in) solo.
  Future<void> _mostrarDialogoAtaque(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Atacar ${_formatName(destino)}'),
          content: Text(
            '¿Confirmas el ataque de ${_formatName(origen)} a ${_formatName(destino)}?\n\n'
            'Todas tus tropas lucharán hasta conquistar o quedarse con 1.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(gameProvider.notifier).cancelarAtaque();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _enviarAtaquePorHttp(
                  context: context,
                  dialogContext: dialogContext,
                  ref: ref,
                  origen: origen,
                  destino: destino,
                );
              },
              child: const Text('¡Atacar!'),
            ),
          ],
        );
      },
    );
  }

  // --- DIÁLOGO DE FORTIFICACIÓN — slider para elegir cuántas tropas mover ---
  Future<void> _mostrarDialogoFortificacion(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
    int tropasOrigen,
  ) async {
    // Dejamos siempre al menos 1 en origen
    final maxMover = (tropasOrigen - 1).clamp(1, tropasOrigen - 1);
    int tropasAMover = maxMover;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Mover tropas a ${_formatName(destino)}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'De ${_formatName(origen)} → ${_formatName(destino)}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$tropasAMover',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        onPressed: tropasAMover > 1
                            ? () => setDialogState(() => tropasAMover--)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tropasAMover.toDouble(),
                          min: 1,
                          max: maxMover.toDouble(),
                          onChanged: (v) => setDialogState(() => tropasAMover = v.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        onPressed: tropasAMover < maxMover
                            ? () => setDialogState(() => tropasAMover++)
                            : null,
                      ),
                    ],
                  ),
                  Text('Disponibles: $tropasOrigen (mín. 1 se queda en origen)'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).cancelarAtaque();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final partidaId = ref.read(webSocketProvider).currentPartidaId;
                    if (partidaId == null) return;

                    try {
                      final dio = ref.read(dioProvider);
                      await dio.post(
                        '/partidas/$partidaId/fortificar',
                        data: {
                          'origen': origen,
                          'destino': destino,
                          'tropas': tropasAMover,
                        },
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ref.read(gameProvider.notifier).cancelarAtaque();
                    } on DioException catch (e) {
                      final detalle = e.response?.data?.toString() ?? e.message;
                      debugPrint('🔴 ERROR fortificacion: $detalle');
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $detalle')),
                      );
                    }
                  },
                  child: const Text('Mover'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoRefuerzo(
    BuildContext context,
    WidgetRef ref,
    String territorio,
  ) async {
    final username = ref.read(authProvider).user?.username ?? '';
    final reserva = ref.read(gameProvider).jugadores[username]?.tropasReserva ?? 0;

    if (reserva <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes tropas en reserva.')),
      );
      return;
    }

    int tropasAEnviar = 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Reforzar ${_formatName(territorio)}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reserva disponible: $reserva', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  Text(
                    '$tropasAEnviar',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        onPressed: tropasAEnviar > 1
                            ? () => setDialogState(() => tropasAEnviar--)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tropasAEnviar.toDouble(),
                          min: 1,
                          max: reserva.toDouble(),
                          onChanged: (v) => setDialogState(() => tropasAEnviar = v.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        onPressed: tropasAEnviar < reserva
                            ? () => setDialogState(() => tropasAEnviar++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).cancelarAtaque();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final partidaId = ref.read(webSocketProvider).currentPartidaId;
                    if (partidaId == null) return;

                    try {
                      final dio = ref.read(dioProvider);
                      await dio.post(
                        '/partidas/$partidaId/colocar_tropas',
                        data: {
                          'territorio_id': territorio,
                          'tropas': tropasAEnviar,
                        },
                      );

                      final estadoActual = ref.read(gameProvider);
                      final faseActual = estadoActual.faseActual.trim().toLowerCase();
                      final tropasReservaRestantes =
                          estadoActual.jugadores[username]?.tropasReserva ?? 0;

                      if (faseActual == 'refuerzo' && tropasReservaRestantes <= 0) {
                        await dio.post('/partidas/$partidaId/pasar_fase');
                        ref.read(gameProvider.notifier).reiniciarTemporizador();
                      }

                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } on DioException catch (e) {
                      final detalle = e.response?.data?.toString() ?? e.message;
                      debugPrint('🔴 ERROR refuerzo: $detalle');
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $detalle')),
                      );
                    }
                  },
                  child: const Text('Reforzar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _enviarAtaquePorHttp({
    required BuildContext context,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required String origen,
    required String destino,
  }) async {
    final dio = ref.read(dioProvider);
    final partidaId = ref.read(webSocketProvider).currentPartidaId;

    if (partidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no hay partida activa conectada.')),
      );
      return;
    }

    try {
      // Sin tropas_a_mover — el backend resuelve el combate completo solo
      await dio.post(
        '/partidas/$partidaId/ataque',
        data: {
          'territorio_origen_id': origen,
          'territorio_destino_id': destino,
        },
      );

      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
      ref.read(gameProvider.notifier).cancelarAtaque();
    } on DioException catch (e) {
      final detalle = e.response?.data?.toString() ?? e.message;
      debugPrint('🔴 ERROR ATAQUE ${e.response?.statusCode}: $detalle');

      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${e.response?.statusCode}: $detalle')),
      );
    }
  }
}