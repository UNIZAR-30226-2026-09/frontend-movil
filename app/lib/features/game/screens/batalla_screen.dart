import 'dart:convert'; // Para el jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/features/map/widgets/interactive_game_map.dart';
import 'package:soberania/features/map/services/map_loader.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/map/widgets/action_panel.dart';

class BatallaScreen extends ConsumerStatefulWidget {
  const BatallaScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<BatallaScreen> createState() => _BatallaScreenState();
}

class _BatallaScreenState extends ConsumerState<BatallaScreen> {
    late final Future<GameMap> _mapFuture;

    String _formatName(String id) {
      return id.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
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
          next.ultimoResultadoAtaque != null && next.versionResultadoAtaque > prevVersion;

      if (!hayNuevoResultado) {
        return;
      }

      final resultado = next.ultimoResultadoAtaque!;
      final titulo = 'Ataque en ${_formatName(resultado.destino)}';
      final mensaje =
          'Has perdido ${resultado.bajasAtacante} tropa(s). '
          'El enemigo perdio ${resultado.bajasDefensor} tropa(s). '
          '${resultado.victoria ? 'Territorio conquistado.' : 'El territorio resiste.'}';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        showDialog<void>(
          context: context,
          builder: (dialogContext) {
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
      });
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.title)),
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
            ],
          );
        },
      ),
      
      // --- BOTÓN TEMPORAL DE PRUEBAS (BORRAR PARA EL COMMIT FINAL) ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          const fakeJsonString = '''
          {
            "fase_actual": "ATAQUE",
            "turno_actual": "nick",
            "jugadores": {
              "nick": {"tropas_reserva": 5},
              "roldi": {"tropas_reserva": 0}
            },
            "mapa": {
              "hoya_de_huesca": {"owner_id": "nick", "units": 10},
              "monegros": {"owner_id": "roldi", "units": 3} 
            }
          }
          ''';
          final fakeJson = jsonDecode(fakeJsonString);
          ref.read(gameProvider.notifier).actualizarDesdeServidor(fakeJson);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Datos inyectados! Prueba a tocar Huesca o Zaragoza.'))
          );
        },
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
      // --------------------------------------------------------------
    );
  }
}