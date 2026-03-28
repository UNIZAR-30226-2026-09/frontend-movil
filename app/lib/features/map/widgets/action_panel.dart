import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return id.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? '';
    final origenSeleccionado = gameState.origenSeleccionado;
    final esMiTurno = username.isNotEmpty && gameState.turnoDe == username;
    final puedeAtacar = gameState.faseActual == 'ataque_convencional' && esMiTurno;

    ref.listen<GameState>(gameProvider, (previous, next) {
      final destinoAcabaDeSeleccionarse =
          (previous?.destinoSeleccionado == null) && next.destinoSeleccionado != null;

      if (!destinoAcabaDeSeleccionarse || _dialogoAtaqueAbierto) return;

      final origen = next.origenSeleccionado;
      final destino = next.destinoSeleccionado;
      if (origen == null || destino == null) return;

      _dialogoAtaqueAbierto = true;
      final unidadesDisponibles = next.mapa[origen]?.units ?? 0;

      _mostrarDialogoAtaque(context, ref, origen, destino, unidadesDisponibles)
          .whenComplete(() => _dialogoAtaqueAbierto = false);
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
            )
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
                const Text(
                  'Selecciona el territorio objetivo en el mapa...',
                  style: TextStyle(fontStyle: FontStyle.italic),
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
                          ? () => _mostrarDialogoRefuerzo(context, ref, origenSeleccionado)
                          : null,
                      icon: const Icon(Icons.add_box),
                      label: const Text('Reforzar'),
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

  Future<void> _mostrarDialogoRefuerzo(
    BuildContext context,
    WidgetRef ref,
    String territorio,
  ) async {
    // Tropas disponibles en reserva del jugador actual
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
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

  Future<void> _mostrarDialogoAtaque(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
    int unidadesDisponibles,
  ) async {
    int tropasAEnviar = unidadesDisponibles > 1 ? unidadesDisponibles - 1 : 1;
    int maxTropas = unidadesDisponibles > 0 ? unidadesDisponibles : 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Text('Atacar a ${_formatName(destino)}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Cuántas tropas enviarás al frente?', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text(
                    '$tropasAEnviar',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          max: maxTropas.toDouble(),
                          onChanged: (val) => setDialogState(() => tropasAEnviar = val.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        onPressed: tropasAEnviar < maxTropas
                            ? () => setDialogState(() => tropasAEnviar++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Disponibles en origen: $unidadesDisponibles'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).cancelarAtaque();
                    dialogContext.pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: unidadesDisponibles > 0
                      ? () async {
                          await _enviarAtaquePorHttp(
                            context: context,
                            dialogContext: dialogContext,
                            ref: ref,
                            origen: origen,
                            destino: destino,
                            tropasAEnviar: tropasAEnviar,
                          );
                        }
                      : null,
                  child: const Text('¡Atacar!'),
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
    required int tropasAEnviar,
  }) async {
    final dio = ref.read(dioProvider);

    // Leemos el ID de la partida activa del WebSocket provider.
    // Cuando Alexis conecte el lobby, esto llega automáticamente.
    final partidaId = ref.read(webSocketProvider).currentPartidaId;

    if (partidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no hay partida activa conectada.')),
      );
      return;
    }

    try {
      await dio.post(
        '/partidas/$partidaId/ataque',
        data: {
          'territorio_origen_id': origen,
          'territorio_destino_id': destino,
          'tropas_a_mover': tropasAEnviar,
        },
      );

      if (!dialogContext.mounted) return;
      dialogContext.pop();
      ref.read(gameProvider.notifier).cancelarAtaque();

    } on DioException catch (e) {
      // Imprimimos el detalle real del error para saber qué falla
      final detalle = e.response?.data?.toString() ?? e.message;
      debugPrint('🔴 ERROR ATAQUE ${e.response?.statusCode}: $detalle');

      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${e.response?.statusCode}: $detalle')),
      );
    }
  }
}