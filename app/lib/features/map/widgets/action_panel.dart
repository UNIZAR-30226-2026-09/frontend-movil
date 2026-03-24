import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';

class ActionPanel extends ConsumerStatefulWidget {
  const ActionPanel({super.key});

  @override
  ConsumerState<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends ConsumerState<ActionPanel> {
  bool _dialogoAtaqueAbierto = false;

  // Limpiamos el nombre feo de la bbdd (hoya_de_huesca -> Hoya De Huesca)
  String _formatName(String id) {
    return id.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final origenSeleccionado = gameState.origenSeleccionado;

    // Escuchador para abrir el popup cuando se selecciona un destino
    ref.listen<GameState>(gameProvider, (previous, next) {
      final destinoAcabaDeSeleccionarse =
          (previous?.destinoSeleccionado == null) && next.destinoSeleccionado != null;

      if (!destinoAcabaDeSeleccionarse || _dialogoAtaqueAbierto) {
        return;
      }

      final origen = next.origenSeleccionado;
      final destino = next.destinoSeleccionado;
      if (origen == null || destino == null) {
        return;
      }

      _dialogoAtaqueAbierto = true;
      final unidadesDisponibles = next.mapa[origen]?.units ?? 0;

      _mostrarDialogoAtaque(
        context,
        ref,
        origen,
        destino,
        unidadesDisponibles,
      ).whenComplete(() {
        _dialogoAtaqueAbierto = false;
      });
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
                  )
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
                const Text('Selecciona el territorio objetivo en el mapa...', style: TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).cancelarAtaque();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
              if (!gameState.esperandoDestino) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: gameState.faseActual == 'ATAQUE'
                          ? () {
                              ref.read(gameProvider.notifier).prepararAtaque();
                            }
                          : null,
                      icon: const Icon(Icons.sports_kabaddi),
                      label: const Text('Atacar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: gameState.faseActual == 'REFUERZO'
                          ? () {
                              debugPrint('Reforzando $origenSeleccionado');
                            }
                          : null,
                      icon: const Icon(Icons.add_box),
                      label: const Text('Reforzar'),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP REESCRITO SIN TEXTFIELD PARA EVITAR BUGS DE TECLADO ---
  Future<void> _mostrarDialogoAtaque(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
    int unidadesDisponibles,
  ) async {
    // Si tienes 0 unidades fallaría, le forzamos a 1 como mínimo para la UI
    int tropasAEnviar = unidadesDisponibles > 1 ? unidadesDisponibles - 1 : 1; 
    int maxTropas = unidadesDisponibles > 0 ? unidadesDisponibles : 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Obliga a tocar un botón para cerrar
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
                  
                  // El número gigante molón
                  Text(
                    '$tropasAEnviar',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  
                  // Los botones de +/- que salvan el día
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        onPressed: tropasAEnviar > 1
                            ? () => setDialogState(() => tropasAEnviar--)
                            : null,
                      ),
                      // Slider opcional en medio
                      Expanded(
                        child: Slider(
                          value: tropasAEnviar.toDouble(),
                          min: 1,
                          max: maxTropas.toDouble(),
                          onChanged: (val) {
                            setDialogState(() => tropasAEnviar = val.toInt());
                          },
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
                      ? () {
                          final datosAtaque = {
                            'origen': origen,
                            'destino': destino,
                            'tropas': tropasAEnviar,
                          };

                          // --- NUESTRO CHIVATO VISUAL PARA LA TERMINAL ---
                          debugPrint('🚀 ENVIANDO AL BACKEND: {"accion": "ATAQUE", ...$datosAtaque}');
                          
                          // ¡POR FIN ENVIAMOS EL EVENTO AL BACKEND!
                          ref.read(webSocketProvider.notifier).emitirEvento('ATAQUE', datosAtaque);

                          dialogContext.pop();
                          ref.read(gameProvider.notifier).cancelarAtaque();
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
}