import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/territory_model.dart';
import '../services/graph_service.dart';
import '../services/map_loader.dart';

// 1. Proveedor del Grafo
final graphServiceProvider = FutureProvider<GraphService>((ref) async {
  final gameData = await MapLoader.loadMap(); 
  // Según tu map_loader.dart, gameData tiene una propiedad 'comarcas' que es List<Comarca>
  return GraphService(gameData.comarcas); 
});

// 2. Estado del Juego
class GameState {
  final String? origenSeleccionado;
  final Set<String> comarcasResaltadas;

  GameState({this.origenSeleccionado, this.comarcasResaltadas = const {}});

  GameState copyWith({String? origen, Set<String>? resaltadas}) {
    return GameState(
      origenSeleccionado: origen ?? origenSeleccionado,
      comarcasResaltadas: resaltadas ?? comarcasResaltadas,
    );
  }
}

// 3. Notificador (USANDO NOTIFIER PARA RIVERPOD 3)
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => GameState();

  void seleccionarComarca(String id) async {
    if (state.origenSeleccionado == id) {
      state = GameState();
      return;
    }

    state = state.copyWith(origen: id);
    
    final graphService = await ref.read(graphServiceProvider.future);
    final alcanzables = graphService.obtenerComarcasEnRango(id, 1);
    state = state.copyWith(resaltadas: alcanzables);
  }
}

// 4. Proveedor Global
final gameProvider = NotifierProvider<GameNotifier, GameState>(() => GameNotifier());