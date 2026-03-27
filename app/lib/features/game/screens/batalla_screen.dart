import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/features/map/services/map_loader.dart';
import 'package:soberania/features/map/widgets/action_panel.dart';
import 'package:soberania/features/map/widgets/interactive_game_map.dart';

class BatallaScreen extends ConsumerStatefulWidget {
  const BatallaScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<BatallaScreen> createState() => _BatallaScreenState();
}

class _BatallaScreenState extends ConsumerState<BatallaScreen> {
  late final Future<GameMap> _mapFuture;

  String _formatName(String id) {
    return id
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _mapFuture = MapLoader.loadMap();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (previous, next) {
      final prevVersion = previous?.versionResultadoAtaque ?? 0;
      final hayNuevoResultado =
          next.ultimoResultadoAtaque != null &&
          next.versionResultadoAtaque > prevVersion;

      if (!hayNuevoResultado) return;

      final resultado = next.ultimoResultadoAtaque!;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Mostramos el resultado del combate
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final titulo = 'Ataque en ${_formatName(resultado.destino)}';
            final mensaje =
                'Has perdido ${resultado.bajasAtacante} tropa(s). '
                'El enemigo perdió ${resultado.bajasDefensor} tropa(s). '
                '${resultado.victoria ? '¡Territorio conquistado!' : 'El territorio resiste.'}';

            return AlertDialog(
              title: Text(titulo),
              content: Text(mensaje),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(gameProvider.notifier).limpiarResultadoAtaque();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );

        // Si fue victoria, el backend bloquea ataques hasta que movamos tropas
        if (resultado.victoria && mounted) {
          await _mostrarDialogoMoverConquista(resultado.destino);
        }
      });
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<GameMap>(
        future: _mapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No hay mapa.'));
          }

          return Stack(
            children: [
              InteractiveGameMap(
                gameMap: snapshot.data!,
                onTapComarca: (c) {
                  ref.read(gameProvider.notifier).seleccionarComarca(
                    c.id,
                    vecinosDelNodoTocado: c.adjacentTo,
                  );
                },
                minScale: 1.0,
                maxScale: 5.0,
              ),
              const ActionPanel(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      // go_router para navegar — consistente con el resto de la app
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoMoverConquista(String territorioConquistado) async {
    final origen = ref.read(gameProvider).origenSeleccionado;
    final tropasOrigen = ref.read(gameProvider).mapa[origen]?.units ?? 1;

    // Máximo movible: todas menos 1 que se queda de guarnición en origen.
    // Si origen tiene 1 tropa el clamp lo fuerza a 1 — el backend lo rechazará
    // pero al menos el diálogo no peta.
    final maxMover = (tropasOrigen - 1).clamp(1, tropasOrigen - 1);
    int tropasAMover = maxMover;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('¡${_formatName(territorioConquistado)} conquistado!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mueve tropas al nuevo territorio para consolidar la conquista.'),
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
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
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
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        onPressed: tropasAMover < maxMover
                            ? () => setDialogState(() => tropasAMover++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final partidaId = ref.read(webSocketProvider).currentPartidaId;
                    if (partidaId == null) return;

                    try {
                      final dio = ref.read(dioProvider);
                      await dio.post(
                        '/partidas/$partidaId/mover_conquista',
                        data: {'tropas': tropasAMover},
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } on DioException catch (e) {
                      final detalle = e.response?.data?.toString() ?? e.message;
                      debugPrint('🔴 ERROR mover_conquista: $detalle');
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $detalle')),
                      );
                    }
                  },
                  child: const Text('Mover tropas'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}