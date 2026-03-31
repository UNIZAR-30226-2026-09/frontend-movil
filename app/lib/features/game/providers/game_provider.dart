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

  factory TerritoryState.fromJson(Map<String, dynamic> json) {
    return TerritoryState(
      ownerId: json['owner_id'] ?? '',
      units: json['units'] ?? 0,
    );
  }
}

class PlayerState {
  final int tropasReserva;
  // El backend manda numero_jugador (1-4) para asignar colores de forma
  // consistente entre todos los clientes sin depender del orden de lista.
  final int numeroJugador;

  PlayerState({required this.tropasReserva, this.numeroJugador = 1});

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      tropasReserva: json['tropas_reserva'] ?? 0,
      numeroJugador: json['numero_jugador'] ?? 1,
    );
  }
}

class AttackResultState {
  final String origen;
  final String destino;
  final int bajasAtacante;
  final int bajasDefensor;
  final bool victoria;
  // El backend ya no manda dados — manda las tropas restantes tras el combate completo
  final int tropasRestantesOrigen;
  final int tropasRestantesDefensor;

  AttackResultState({
    required this.origen,
    required this.destino,
    required this.bajasAtacante,
    required this.bajasDefensor,
    required this.victoria,
    required this.tropasRestantesOrigen,
    required this.tropasRestantesDefensor,
  });

  factory AttackResultState.fromJson(Map<String, dynamic> json) {
    return AttackResultState(
      origen: (json['origen'] ?? '').toString(),
      destino: (json['destino'] ?? '').toString(),
      bajasAtacante: json['bajas_atacante'] ?? 0,
      bajasDefensor: json['bajas_defensor'] ?? 0,
      victoria: json['victoria'] ?? false,
      tropasRestantesOrigen: json['tropas_restantes_origen'] ?? 0,
      tropasRestantesDefensor: json['tropas_restantes_defensor'] ?? 0,
    );
  }
}

// --- EL ESTADO GLOBAL (MEZCLA SERVIDOR + UI) ---

class GameState {
  final String? origenSeleccionado;
  final String? destinoSeleccionado;
  final bool esperandoDestino;
  final Set<String> comarcasResaltadas;
  final AttackResultState? ultimoResultadoAtaque;
  final int versionResultadoAtaque;

  final Map<String, TerritoryState> mapa; 
  final Map<String, PlayerState> jugadores;
  final String turnoDe;
  final String faseActual;

  GameState({
    this.origenSeleccionado,
    this.destinoSeleccionado,
    this.esperandoDestino = false,
    this.comarcasResaltadas = const {},
    this.ultimoResultadoAtaque,
    this.versionResultadoAtaque = 0,
    this.mapa = const {},
    this.jugadores = const {},
    this.turnoDe = '',
    this.faseActual = 'ESPERA',
  });

  GameState copyWith({
    String? origenSeleccionado,
    String? destinoSeleccionado,
    bool? esperandoDestino,
    Set<String>? comarcasResaltadas,
    AttackResultState? ultimoResultadoAtaque,
    int? versionResultadoAtaque,
    Map<String, TerritoryState>? mapa,
    Map<String, PlayerState>? jugadores,
    String? turnoDe,
    String? faseActual,
    bool clearOrigen = false, 
    bool clearDestino = false,
    bool clearResultadoAtaque = false,
  }) {
    return GameState(
      origenSeleccionado: clearOrigen ? null : (origenSeleccionado ?? this.origenSeleccionado),
      destinoSeleccionado: clearDestino ? null : (destinoSeleccionado ?? this.destinoSeleccionado),
      esperandoDestino: esperandoDestino ?? this.esperandoDestino,
      comarcasResaltadas: comarcasResaltadas ?? this.comarcasResaltadas,
      ultimoResultadoAtaque: clearResultadoAtaque ? null : (ultimoResultadoAtaque ?? this.ultimoResultadoAtaque),
      versionResultadoAtaque: versionResultadoAtaque ?? this.versionResultadoAtaque,
      mapa: mapa ?? this.mapa,
      jugadores: jugadores ?? this.jugadores,
      turnoDe: turnoDe ?? this.turnoDe,
      faseActual: faseActual ?? this.faseActual,
    );
  }
}

// 3. Notificador (El controlador del estado)
class GameNotifier extends Notifier<GameState> {
  static const List<String> _faseOrden = <String>[
    'refuerzo',
    'ataque_convencional',
    'fortificacion',
  ];

  @override
  GameState build() => GameState();

  String _normalizarFase(String fase) {
    return fase.trim().toLowerCase();
  }

  void agregarJugador(String username) {
    if (state.jugadores.containsKey(username)) return;

    final jugadoresActualizados = Map<String, PlayerState>.from(state.jugadores);
    jugadoresActualizados[username] = PlayerState(tropasReserva: 0);
    state = state.copyWith(jugadores: jugadoresActualizados);
  }

  void actualizarTerritorioConDueno({
    required String territorioId,
    required int units,
    required String nuevoOwner,
  }) {
    final mapaActual = Map<String, TerritoryState>.from(state.mapa);
    mapaActual[territorioId] = TerritoryState(
      ownerId: nuevoOwner,
      units: units,
    );
    state = state.copyWith(mapa: mapaActual);
  }

  void actualizarDesdeServidor(Map<String, dynamic> jsonPartida) {
    final mapaJson = jsonPartida['mapa'] as Map<String, dynamic>?;
    final nuevoMapa = mapaJson != null
        ? mapaJson.map((key, value) => MapEntry(key, TerritoryState.fromJson(value)))
        : null;

    final jugadoresJson = jsonPartida['jugadores'] as Map<String, dynamic>?;
    final nuevosJugadores = jugadoresJson != null
        ? jugadoresJson.map((key, value) => MapEntry(key, PlayerState.fromJson(value)))
        : null;

    final faseRaw = jsonPartida['fase_actual'] 
        ?? jsonPartida['nueva_fase'] 
        ?? state.faseActual;
    final faseNormalizada = faseRaw.toString().toLowerCase();

    final turnoRaw = jsonPartida['turno_actual'] 
        ?? jsonPartida['turno_de'] 
        ?? jsonPartida['jugador_activo'] 
        ?? state.turnoDe;

    state = state.copyWith(
      mapa: nuevoMapa,
      jugadores: nuevosJugadores,
      turnoDe: turnoRaw.toString(),
      faseActual: faseNormalizada,
    );
  }

  void seleccionarComarca(String id, {List<String>? vecinosDelNodoTocado}) async {
    if (state.esperandoDestino) {
      if (state.origenSeleccionado != null && id != state.origenSeleccionado) {
        // En fortificacion no hace falta ser vecino — el backend valida el camino con NetworkX
        final faseActual = _normalizarFase(state.faseActual);
        final esFortificacion = faseActual == 'fortificacion';
        final esVecinoDelOrigen = vecinosDelNodoTocado?.contains(state.origenSeleccionado) ?? false;

        if (!esFortificacion && !esVecinoDelOrigen) {
          return;
        }

        state = state.copyWith(
          destinoSeleccionado: id,
          esperandoDestino: false,
          comarcasResaltadas: const {},
        );
      }
      return;
    }

    if (state.origenSeleccionado == id) {
      state = state.copyWith(
        clearOrigen: true,
        clearDestino: true,
        esperandoDestino: false,
        comarcasResaltadas: const {},
      );
      return;
    }
    
    final graphService = await ref.read(graphServiceProvider.future);
    final alcanzables = graphService.obtenerComarcasEnRango(id, 1);
    
    state = state.copyWith(
      origenSeleccionado: id,
      clearDestino: true,
      esperandoDestino: false,
      comarcasResaltadas: alcanzables,
    );
  }

  void prepararAtaque() {
    if (state.origenSeleccionado == null) return;

    state = state.copyWith(
      esperandoDestino: true,
      clearDestino: true,
    );
  }

  void cancelarAtaque() {
    state = state.copyWith(
      clearDestino: true,
      esperandoDestino: false,
      comarcasResaltadas: const {},
    );
  }

  void registrarResultadoAtaque(Map<String, dynamic> payload) {
    state = state.copyWith(
      ultimoResultadoAtaque: AttackResultState.fromJson(payload),
      versionResultadoAtaque: state.versionResultadoAtaque + 1,
    );
  }

  void limpiarResultadoAtaque() {
    state = state.copyWith(clearResultadoAtaque: true);
  }

  void avanzarFasePanel() {
    final faseActual = _normalizarFase(state.faseActual);
    final currentIndex = _faseOrden.indexOf(faseActual);

    if (currentIndex == -1) {
      state = state.copyWith(faseActual: _faseOrden.first);
      return;
    }

    final nextIndex = (currentIndex + 1) % _faseOrden.length;
    state = state.copyWith(faseActual: _faseOrden[nextIndex]);
  }

  void actualizarTerritorio({required String territorioId, required int units}) {
    final mapaActual = Map<String, TerritoryState>.from(state.mapa);
    final territorioActual = mapaActual[territorioId];
    if (territorioActual == null) return;

    mapaActual[territorioId] = TerritoryState(
      ownerId: territorioActual.ownerId,
      units: units,
    );

    state = state.copyWith(mapa: mapaActual);
  }

  void resetState() {
    state = GameState();
  }
}

// 4. Proveedor Global
final gameProvider = NotifierProvider<GameNotifier, GameState>(() => GameNotifier());