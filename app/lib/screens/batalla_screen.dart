import 'package:flutter/material.dart';
import 'package:soberania/widgets/interactive_game_map.dart';
import '../services/map_loader.dart';
import '../services/map_painter.dart';

class BatallaScreen extends StatefulWidget {
  const BatallaScreen({super.key, required this.title});

  final String title;

  @override
  State<BatallaScreen> createState() => _BatallaScreenState();
}

class _BatallaScreenState extends State<BatallaScreen> {
    late final Future<GameMap> _mapFuture;
    @override
    void initState() {
      super.initState();
      _mapFuture = MapLoader.loadMap();
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<GameMap>(
        future: _mapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error cargando el mapa: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar el mapa.'));
          }

          

          // Para que el CustomPaint ocupe toda la pantalla disponible
          return InteractiveGameMap(
            gameMap: snapshot.data!,
            onTapComarca: (c) => debugPrint('Comarca tocada: ${c.id} - ${c.name}'),
            minScale: 1.0,
            maxScale: 5.0,
          );
        },
      ),
    );
  }
}