import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/services/graph_service.dart';
import '../../map/services/map_loader.dart';

// 1. Proveedor del Grafo (Se queda igual, carga la topología base del mapa)
final graphServiceProvider = FutureProvider<GraphService>((ref) async {
  final gameData = await MapLoader.loadMap(); 
  return GraphService(gameData.comarcas); 
});

// --- CLASES PARA MAPEAR EL JSON DE FASTAPI ---

class TerritoryState {
  final String ownerId;
  final int units;

  TerritoryState({required this.ownerId, required this.units});

  // Traducimos el diccionario de Python (TerritorioBase) a un objeto de Dart
  factory TerritoryState.fromJson(Map<String, dynamic> json) {
    return TerritoryState(
      ownerId: json['owner_id'] ?? '',
      units: json['units'] ?? 0,
    );
  }
}

class PlayerState {
  final int tropasReserva;
  
  PlayerState({required this.tropasReserva});

  // Traducimos el JugadorBase de FastAPI
  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      tropasReserva: json['tropas_reserva'] ?? 0,
    );
  }
}

// --- EL ESTADO GLOBAL (MEZCLA SERVIDOR + UI) ---

class GameState {
  // Estado Local (UI - Lo que toca el usuario en la pantalla)
  final String? origenSeleccionado;
  final Set<String> comarcasResaltadas;

  // Estado del Servidor (La verdad absoluta que nos manda el backend)
  final Map<String, TerritoryState> mapa; 
  final Map<String, PlayerState> jugadores;
  final String turnoDe;
  final String faseActual;

  GameState({
    this.origenSeleccionado,
    this.comarcasResaltadas = const {},
    this.mapa = const {},
    this.jugadores = const {},
    this.turnoDe = '',
    this.faseActual = 'ESPERA',
  });

  // Usamos copyWith para mantener la inmutabilidad de Riverpod.
  // Le metemos 'clearOrigen' como un truco para poder forzar el origen a null cuando deseleccionamos.
  GameState copyWith({
    String? origenSeleccionado,
    Set<String>? comarcasResaltadas,
    Map<String, TerritoryState>? mapa,
    Map<String, PlayerState>? jugadores,
    String? turnoDe,
    String? faseActual,
    bool clearOrigen = false, 
  }) {
    return GameState(
      origenSeleccionado: clearOrigen ? null : (origenSeleccionado ?? this.origenSeleccionado),
      comarcasResaltadas: comarcasResaltadas ?? this.comarcasResaltadas,
      mapa: mapa ?? this.mapa,
      jugadores: jugadores ?? this.jugadores,
      turnoDe: turnoDe ?? this.turnoDe,
      faseActual: faseActual ?? this.faseActual,
    );
  }
}

// 3. Notificador (El controlador del estado)
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => GameState();

  // Esta es la función mágica que llamaremos cada vez que el WebSocket escupa un JSON
  void actualizarDesdeServidor(Map<String, dynamic> jsonPartida) {
    // Parseamos el mapa: recorremos las claves (comarcas) y creamos los objetos TerritoryState
    final mapaJson = jsonPartida['mapa'] as Map<String, dynamic>? ?? {};
    final nuevoMapa = mapaJson.map((key, value) => MapEntry(key, TerritoryState.fromJson(value)));

    // Parseamos los datos de los jugadores (reservas, etc)
    final jugadoresJson = jsonPartida['jugadores'] as Map<String, dynamic>? ?? {};
    final nuevosJugadores = jugadoresJson.map((key, value) => MapEntry(key, PlayerState.fromJson(value)));

    // Pegamos el cambiazo al estado global. Si el backend no manda turno o fase, conservamos lo que teníamos.
    state = state.copyWith(
      mapa: nuevoMapa,
      jugadores: nuevosJugadores,
      turnoDe: jsonPartida['turno_actual'] ?? state.turnoDe,
      faseActual: jsonPartida['fase_actual'] ?? state.faseActual,
    );
  }

  void seleccionarComarca(String id) async {
    // Si toco la misma comarca que ya estaba seleccionada, limpio la selección
    if (state.origenSeleccionado == id) {
      state = state.copyWith(clearOrigen: true, comarcasResaltadas: {});
      return;
    }
    
    final graphService = await ref.read(graphServiceProvider.future);
    final alcanzables = graphService.obtenerComarcasEnRango(id, 1);
    
    state = state.copyWith(
      origenSeleccionado: id,
      comarcasResaltadas: alcanzables,
    );
  }
}

// 4. Proveedor Global
final gameProvider = NotifierProvider<GameNotifier, GameState>(() => GameNotifier());