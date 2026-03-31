import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import '../../../shared/api/dio_provider.dart';

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

    final double panelHeight = gameState.esperandoDestino ? 280.0 : 220.0;
    final bool isVisible = origenSeleccionado != null;
    final territoryData = origenSeleccionado != null ? gameState.mapa[origenSeleccionado] : null;
    final owner = territoryData?.ownerId ?? 'Neutral';
    final units = territoryData?.units ?? 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: isVisible ? 0 : -panelHeight,
      left: 0,
      right: 0,
      height: panelHeight,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (origenSeleccionado != null) {
                        ref.read(gameProvider.notifier).seleccionarComarca(origenSeleccionado);
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text('Dueño: $owner'),
                  const Spacer(),
                  const Icon(Icons.shield, size: 20),
                  const SizedBox(width: 8),
                  Text('Tropas: $units', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (gameState.esperandoDestino) ...[
                const SizedBox(height: 12),
                Text(
                  // El texto cambia según la fase para que el usuario sepa qué está haciendo
                  puedeAtacar
                      ? 'Selecciona el territorio a atacar...'
                      : 'Selecciona el territorio destino...',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.read(gameProvider.notifier).cancelarAtaque(),
                  child: const Text('Cancelar'),
                ),
              ],
              if (!gameState.esperandoDestino) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: puedeAtacar
                          ? () => ref.read(gameProvider.notifier).prepararAtaque()
                          : null,
                      icon: const Icon(Icons.sports_kabaddi),
                      label: const Text('Atacar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: gameState.faseActual == 'refuerzo' && esMiTurno && origenSeleccionado != null
                          ? () => _mostrarDialogoRefuerzo(context, ref, origenSeleccionado!)
                          : null,
                      icon: const Icon(Icons.add_box),
                      label: const Text('Reforzar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: puedeFortificar && origenSeleccionado != null && units > 1
                          ? () => ref.read(gameProvider.notifier).prepararAtaque()
                          : null,
                      icon: const Icon(Icons.fort),
                      label: const Text('Mover'),
                    ),
                  ],
                ),
              ],
            ],
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