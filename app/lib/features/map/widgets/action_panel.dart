import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';

class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  // Limpia el ID (ej: hoya_de_huesca -> Hoya De Huesca)
  String _formatName(String id) {
    return id.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos al Cerebro (GameState)
    final gameState = ref.watch(gameProvider);
    final idSeleccionado = gameState.origenSeleccionado;

    const double panelHeight = 220.0;
    final bool isVisible = idSeleccionado != null;

    // Sacamos los datos del territorio seleccionado del mapa del servidor
    final territoryData = idSeleccionado != null ? gameState.mapa[idSeleccionado] : null;
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), 
              blurRadius: 10, 
              offset: const Offset(0, -2),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    idSeleccionado != null ? _formatName(idSeleccionado) : '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (idSeleccionado != null) {
                      // Si cerramos, deseleccionamos en el cerebro
                      ref.read(gameProvider.notifier).seleccionarComarca(idSeleccionado);
                    }
                  },
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Dueño: $owner', style: const TextStyle(fontSize: 16)),
                const Spacer(),
                const Icon(Icons.shield, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text('Tropas: $units', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Atacar: Solo activo si estamos en fase de ATAQUE
                ElevatedButton.icon(
                  onPressed: gameState.faseActual == 'ATAQUE' ? () {
                    debugPrint('Intentando atacar desde $idSeleccionado');
                  } : null,
                  icon: const Icon(Icons.sports_kabaddi),
                  label: const Text('Atacar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
                // Botón de Reforzar: Solo activo en fase de REFUERZO
                ElevatedButton.icon(
                  onPressed: gameState.faseActual == 'REFUERZO' ? () {
                    debugPrint('Reforzando $idSeleccionado');
                  } : null,
                  icon: const Icon(Icons.add_box),
                  label: const Text('Reforzar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}