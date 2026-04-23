import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/services/graph_service.dart';
import '../../map/services/map_loader.dart';

String _normalizeTechId(String raw) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\-]+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');

  return normalized.replaceAll(RegExp(r'_+'), '_');
}

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
  final int monedas;
  final List<String> tecnologiasCompradas;
  final List<String> tecnologiasPredesbloqueadas;

  PlayerState({
    required this.tropasReserva,
    this.numeroJugador = 1,
    this.monedas = 0,
    this.tecnologiasCompradas = const <String>[],
    this.tecnologiasPredesbloqueadas = const <String>[],
  });

  PlayerState copyWith({
    int? tropasReserva,
    int? numeroJugador,
    int? monedas,
    List<String>? tecnologiasCompradas,
    List<String>? tecnologiasPredesbloqueadas,
  }) {
    return PlayerState(
      tropasReserva: tropasReserva ?? this.tropasReserva,
      numeroJugador: numeroJugador ?? this.numeroJugador,
      monedas: monedas ?? this.monedas,
      tecnologiasCompradas: tecnologiasCompradas ?? this.tecnologiasCompradas,
      tecnologiasPredesbloqueadas:
          tecnologiasPredesbloqueadas ?? this.tecnologiasPredesbloqueadas,
    );
  }

  static List<String> _parseTechList(dynamic raw) {
    if (raw == null) return const <String>[];

    if (raw is List) {
      return raw
          .map((item) => _normalizeTechId(item.toString()))
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    }

    if (raw is Map) {
      final output = <String>[];
      for (final entry in raw.entries) {
        final id = _normalizeTechId(entry.key.toString());
        if (id.isEmpty) continue;

        final value = entry.value;
        final unlocked = value == true || value == 1 || value == '1';
        if (unlocked) {
          output.add(id);
        }
      }
      return output;
    }

    return const <String>[];
  }

  static int _parseIntSafe(dynamic raw, {int fallback = 0}) {
    if (raw == null) return fallback;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    final text = raw.toString().trim();
    if (text.isEmpty) return fallback;

    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(text);
    return asDouble?.toInt() ?? fallback;
  }

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      tropasReserva: _parseIntSafe(json['tropas_reserva']),
      numeroJugador: _parseIntSafe(json['numero_jugador'], fallback: 1),
      // Monedas puede venir como `monedas` o `coins`, int/string/null.
      monedas: _parseIntSafe(json['monedas'] ?? json['coins']),
      tecnologiasCompradas: _parseTechList(
        json['tecnologias_compradas'] ??
            json['tecnologias'] ??
            json['techs'] ??
            json['ataques_especiales'],
      ),
      tecnologiasPredesbloqueadas: _parseTechList(
        json['tecnologias_predesbloqueadas'] ??
            json['predesbloqueadas'] ??
            json['techs_predesbloqueadas'] ??
            json['ataques_especiales_predesbloqueados'],
      ),
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
  final bool vistaRegiones;
  final Set<String> comarcasResaltadas;
  final AttackResultState? ultimoResultadoAtaque;
  final int versionResultadoAtaque;

  final Map<String, TerritoryState> mapa;
  final Map<String, PlayerState> jugadores;
  final String turnoDe;
  final String faseActual;
  final int monedasGanadasUltimoTurno;
  final String investigacionCompletada;
  final int tropasRecibidasTurno;
  final int ultimosRefuerzosRecibidos;

  GameState({
    this.origenSeleccionado,
    this.destinoSeleccionado,
    this.esperandoDestino = false,
    this.vistaRegiones = false,
    this.comarcasResaltadas = const {},
    this.ultimoResultadoAtaque,
    this.versionResultadoAtaque = 0,
    this.mapa = const {},
    this.jugadores = const {},
    this.turnoDe = '',
    this.faseActual = 'ESPERA',
    this.monedasGanadasUltimoTurno = 0,
    this.investigacionCompletada = '',
    this.tropasRecibidasTurno = 0,
    this.ultimosRefuerzosRecibidos = 0,
  });

  GameState copyWith({
    String? origenSeleccionado,
    String? destinoSeleccionado,
    bool? esperandoDestino,
    bool? vistaRegiones,
    Set<String>? comarcasResaltadas,
    AttackResultState? ultimoResultadoAtaque,
    int? versionResultadoAtaque,
    Map<String, TerritoryState>? mapa,
    Map<String, PlayerState>? jugadores,
    String? turnoDe,
    String? faseActual,
    int? monedasGanadasUltimoTurno,
    String? investigacionCompletada,
    int? tropasRecibidasTurno,
    int? ultimosRefuerzosRecibidos,
    bool clearOrigen = false,
    bool clearDestino = false,
    bool clearResultadoAtaque = false,
  }) {
    return GameState(
      origenSeleccionado: clearOrigen
          ? null
          : (origenSeleccionado ?? this.origenSeleccionado),
      destinoSeleccionado: clearDestino
          ? null
          : (destinoSeleccionado ?? this.destinoSeleccionado),
      esperandoDestino: esperandoDestino ?? this.esperandoDestino,
      vistaRegiones: vistaRegiones ?? this.vistaRegiones,
      comarcasResaltadas: comarcasResaltadas ?? this.comarcasResaltadas,
      ultimoResultadoAtaque: clearResultadoAtaque
          ? null
          : (ultimoResultadoAtaque ?? this.ultimoResultadoAtaque),
      versionResultadoAtaque:
          versionResultadoAtaque ?? this.versionResultadoAtaque,
      mapa: mapa ?? this.mapa,
      jugadores: jugadores ?? this.jugadores,
      turnoDe: turnoDe ?? this.turnoDe,
      faseActual: faseActual ?? this.faseActual,
      monedasGanadasUltimoTurno:
          monedasGanadasUltimoTurno ?? this.monedasGanadasUltimoTurno,
      investigacionCompletada:
          investigacionCompletada ?? this.investigacionCompletada,
      tropasRecibidasTurno: tropasRecibidasTurno ?? this.tropasRecibidasTurno,
      ultimosRefuerzosRecibidos:
          ultimosRefuerzosRecibidos ?? this.ultimosRefuerzosRecibidos,
    );
  }
}

// 3. Notificador (El controlador del estado)
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => GameState();

  String _normalizarFase(String fase) {
    return fase.trim().toLowerCase();
  }

  bool _hasAnyKey(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return true;
    }
    return false;
  }

  PlayerState _mergePlayerStateDesdeJson(
    PlayerState? previo,
    Map<String, dynamic> valueMap,
  ) {
    final parsed = PlayerState.fromJson(valueMap);
    final base = previo ?? PlayerState(tropasReserva: 0);

    final traeTechCompradas = _hasAnyKey(valueMap, const <String>[
      'tecnologias_compradas',
      'tecnologias',
      'techs',
      'ataques_especiales',
    ]);
    final traeTechPredesbloqueadas = _hasAnyKey(valueMap, const <String>[
      'tecnologias_predesbloqueadas',
      'predesbloqueadas',
      'techs_predesbloqueadas',
      'ataques_especiales_predesbloqueados',
    ]);

    // En eventos parciales mantenemos lo anterior cuando el campo no llega.
    return base.copyWith(
      tropasReserva: valueMap.containsKey('tropas_reserva')
          ? parsed.tropasReserva
          : base.tropasReserva,
      numeroJugador: valueMap.containsKey('numero_jugador')
          ? parsed.numeroJugador
          : base.numeroJugador,
      monedas: _hasAnyKey(valueMap, const <String>['monedas', 'coins'])
          ? parsed.monedas
          : base.monedas,
      tecnologiasCompradas: traeTechCompradas
          ? parsed.tecnologiasCompradas
          : base.tecnologiasCompradas,
      tecnologiasPredesbloqueadas: traeTechPredesbloqueadas
          ? parsed.tecnologiasPredesbloqueadas
          : base.tecnologiasPredesbloqueadas,
    );
  }

  void agregarJugador(String username) {
    if (state.jugadores.containsKey(username)) return;

    final jugadoresActualizados = Map<String, PlayerState>.from(
      state.jugadores,
    );
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

  void actualizarCambioFaseDesdeWs({
    required String nuevaFase,
    required String jugadorActivo,
    required int tropasRecibidas,
  }) {
    final faseNormalizada = _normalizarFase(nuevaFase);
    final jugadoresActualizados = Map<String, PlayerState>.from(
      state.jugadores,
    );
    final refuerzosRecibidos = faseNormalizada == 'refuerzo'
        ? tropasRecibidas
        : 0;
    final resetResumenGestion = faseNormalizada == 'gestion';

    // En refuerzo sumamos las tropas recibidas al jugador activo del evento.
    // Usamos copyWith para no perder el resto de campos del PlayerState.
    if (faseNormalizada == 'refuerzo' &&
        tropasRecibidas > 0 &&
        jugadorActivo.isNotEmpty) {
      final jugadorPrevio = jugadoresActualizados[jugadorActivo];
      final jugadorBase = jugadorPrevio ?? PlayerState(tropasReserva: 0);

      jugadoresActualizados[jugadorActivo] = jugadorBase.copyWith(
        tropasReserva: jugadorBase.tropasReserva + tropasRecibidas,
      );
    }

    // CAMBIO_FASE es la fuente de verdad para fase/turno.
    state = state.copyWith(
      faseActual: faseNormalizada,
      turnoDe: jugadorActivo,
      jugadores: jugadoresActualizados,
      monedasGanadasUltimoTurno: resetResumenGestion
          ? 0
          : state.monedasGanadasUltimoTurno,
      investigacionCompletada: resetResumenGestion
          ? ''
          : state.investigacionCompletada,
      tropasRecibidasTurno: refuerzosRecibidos,
      ultimosRefuerzosRecibidos: refuerzosRecibidos,
    );
  }

  void registrarTrabajoCompletadoDesdeWs({
    required String jugadorId,
    required int monedasGanadas,
    int? monedasTotales,
  }) {
    final jugadoresActualizados = Map<String, PlayerState>.from(
      state.jugadores,
    );

    if (jugadorId.isNotEmpty) {
      final jugadorPrevio = jugadoresActualizados[jugadorId];
      final jugadorBase = jugadorPrevio ?? PlayerState(tropasReserva: 0);
      final monedasCalculadas =
          monedasTotales ??
          (jugadorBase.monedas + (monedasGanadas > 0 ? monedasGanadas : 0));

      jugadoresActualizados[jugadorId] = jugadorBase.copyWith(
        monedas: monedasCalculadas,
      );
    }

    state = state.copyWith(
      jugadores: jugadoresActualizados,
      monedasGanadasUltimoTurno:
          state.monedasGanadasUltimoTurno +
          (monedasGanadas > 0 ? monedasGanadas : 0),
    );
  }

  void registrarInvestigacionCompletadaDesdeWs(String resumen) {
    final texto = resumen.trim();
    if (texto.isEmpty) return;

    state = state.copyWith(investigacionCompletada: texto);
  }

  void actualizarDesdeServidor(Map<String, dynamic> jsonPartida) {
    // Partimos del estado actual y sobrescribimos solo lo que venga del payload.
    // Asi evitamos perder datos en eventos parciales (ej: CAMBIO_FASE).
    Map<String, TerritoryState> mapaActualizado =
        Map<String, TerritoryState>.from(state.mapa);
    Map<String, PlayerState> jugadoresActualizados =
        Map<String, PlayerState>.from(state.jugadores);

    final mapaJsonRaw = jsonPartida['mapa'];
    if (mapaJsonRaw is Map) {
      final mapaJson = Map<String, dynamic>.from(mapaJsonRaw);
      mapaActualizado = mapaJson.map((key, value) {
        final valueMap = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        return MapEntry(key, TerritoryState.fromJson(valueMap));
      });
    }

    final jugadoresJsonRaw = jsonPartida['jugadores'];
    if (jugadoresJsonRaw is Map) {
      final jugadoresJson = Map<String, dynamic>.from(jugadoresJsonRaw);
      jugadoresActualizados = Map<String, PlayerState>.from(state.jugadores);
      jugadoresJson.forEach((key, value) {
        final valueMap = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        jugadoresActualizados[key] = _mergePlayerStateDesdeJson(
          jugadoresActualizados[key],
          valueMap,
        );
      });
    }

    final faseRaw =
        jsonPartida['fase_actual'] ??
        jsonPartida['nueva_fase'] ??
        state.faseActual;
    final faseNormalizada = faseRaw.toString().toLowerCase();

    final turnoRaw =
        jsonPartida['turno_actual'] ??
        jsonPartida['turno_de'] ??
        jsonPartida['jugador_activo'] ??
        state.turnoDe;

    // CAMBIO_FASE suele venir sin bloque de jugadores. Si trae tropas_recibidas,
    // las sumamos al jugador activo para que el HUD se actualice al instante.
    final tropasRecibidasRaw = jsonPartida['tropas_recibidas'];
    final tropasRecibidas = tropasRecibidasRaw is int
        ? tropasRecibidasRaw
        : (tropasRecibidasRaw is num
              ? tropasRecibidasRaw.toInt()
              : int.tryParse(tropasRecibidasRaw?.toString() ?? '') ?? 0);
    final jugadorActivo = turnoRaw.toString();
    final faseEsRefuerzo = faseNormalizada == 'refuerzo';
    final jugadorMapRaw = jugadoresJsonRaw is Map
        ? jugadoresJsonRaw[jugadorActivo]
        : null;
    final jugadorMap = jugadorMapRaw is Map
        ? Map<String, dynamic>.from(jugadorMapRaw)
        : <String, dynamic>{};
    final payloadTraeReservaDelActivo = jugadorMap.containsKey(
      'tropas_reserva',
    );
    final refuerzosRecibidos = faseEsRefuerzo ? tropasRecibidas : 0;

    if (tropasRecibidas > 0 &&
        faseEsRefuerzo &&
        jugadorActivo.isNotEmpty &&
        !payloadTraeReservaDelActivo) {
      final jugadorPrevio = jugadoresActualizados[jugadorActivo];
      final jugadorBase = jugadorPrevio ?? PlayerState(tropasReserva: 0);

      jugadoresActualizados[jugadorActivo] = jugadorBase.copyWith(
        tropasReserva: jugadorBase.tropasReserva + tropasRecibidas,
      );
    }

    state = state.copyWith(
      mapa: mapaActualizado,
      jugadores: Map<String, PlayerState>.from(jugadoresActualizados),
      turnoDe: turnoRaw.toString(),
      faseActual: faseNormalizada,
      tropasRecibidasTurno: refuerzosRecibidos,
      ultimosRefuerzosRecibidos: refuerzosRecibidos,
    );
  }

  void restarTropasReserva({required String jugadorId, required int tropas}) {
    if (jugadorId.isEmpty || tropas <= 0) return;

    final jugadorActual = state.jugadores[jugadorId];
    if (jugadorActual == null) return;

    final nuevaReserva = (jugadorActual.tropasReserva - tropas) < 0
        ? 0
        : (jugadorActual.tropasReserva - tropas);

    final jugadoresActualizados = Map<String, PlayerState>.from(
      state.jugadores,
    );
    jugadoresActualizados[jugadorId] = jugadorActual.copyWith(
      tropasReserva: nuevaReserva,
    );

    state = state.copyWith(jugadores: jugadoresActualizados);
  }

  void marcarTecnologiaComprada({
    required String jugadorId,
    required String tecnologiaId,
  }) {
    if (jugadorId.isEmpty || tecnologiaId.trim().isEmpty) return;

    final techId = _normalizeTechId(tecnologiaId);
    if (techId.isEmpty) return;

    final jugadorActual = state.jugadores[jugadorId];
    if (jugadorActual == null) return;

    if (jugadorActual.tecnologiasCompradas.contains(techId)) return;

    final compradas = List<String>.from(jugadorActual.tecnologiasCompradas)
      ..add(techId);
    final predesbloqueadas = List<String>.from(
      jugadorActual.tecnologiasPredesbloqueadas,
    )..removeWhere((id) => id == techId);

    final jugadoresActualizados = Map<String, PlayerState>.from(
      state.jugadores,
    );
    jugadoresActualizados[jugadorId] = jugadorActual.copyWith(
      tecnologiasCompradas: compradas,
      tecnologiasPredesbloqueadas: predesbloqueadas,
    );

    state = state.copyWith(jugadores: jugadoresActualizados);
  }

  bool _esMismoJugador(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a == b;
  }

  bool _esMiTurnoLocal(String jugadorLocalId) {
    return _esMismoJugador(state.turnoDe, jugadorLocalId);
  }

  bool _esTerritorioMio(String ownerId, String jugadorLocalId) {
    return _esMismoJugador(ownerId, jugadorLocalId);
  }

  bool _tieneAdyacenteEnemigo(String comarcaId) {
    final territorio = state.mapa[comarcaId];
    if (territorio == null) return false;

    final ownerId = territorio.ownerId;
    if (ownerId.isEmpty) return false;

    final graph = ref.read(graphServiceProvider).value;
    if (graph == null) return false;

    final vecinas = graph.obtenerComarcasEnRango(comarcaId, 1);

    for (final vecinaId in vecinas) {
      final vecina = state.mapa[vecinaId];
      if (vecina == null) continue;
      if (vecina.ownerId.isEmpty) continue;

      if (vecina.ownerId != ownerId) {
        return true;
      }
    }

    return false;
  }

  bool _tieneAdyacenteAliado(String comarcaId) {
    final territorio = state.mapa[comarcaId];
    if (territorio == null) return false;

    final ownerId = territorio.ownerId;
    if (ownerId.isEmpty) return false;

    final graph = ref.read(graphServiceProvider).value;
    if (graph == null) return false;

    final vecinas = graph.obtenerComarcasEnRango(comarcaId, 1);

    for (final vecinaId in vecinas) {
      final vecina = state.mapa[vecinaId];
      if (vecina == null) continue;
      if (vecina.ownerId.isEmpty) continue;

      if (vecina.ownerId == ownerId) {
        return true;
      }
    }

    return false;
  }

  bool _puedeSeleccionarseComoOrigen(String comarcaId, String jugadorLocalId) {
    final territorio = state.mapa[comarcaId];
    if (territorio == null) return false;

    final ownerId = territorio.ownerId;
    final tropas = territorio.units;

    if (ownerId.isEmpty) return false;
    if (!_esMiTurnoLocal(jugadorLocalId)) return false;
    if (!_esTerritorioMio(ownerId, jugadorLocalId)) return false;

    switch (state.faseActual.toUpperCase()) {
      case 'REFUERZO':
        return (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;

      case 'GESTION':
        return true;

      case 'ATAQUE_CONVENCIONAL':
        return tropas > 1 && _tieneAdyacenteEnemigo(comarcaId);

      case 'FORTIFICACION':
        return tropas > 1 && _tieneAdyacenteAliado(comarcaId);

      default:
        return false;
    }
  }

  void seleccionarComarca(
    String id, {
      required String jugadorLocalId,
    List<String>? vecinosDelNodoTocado,
  }) async {
    if (state.esperandoDestino) {
      if (state.origenSeleccionado != null && id != state.origenSeleccionado) {
        // En fortificacion no hace falta ser vecino — el backend valida el camino con NetworkX
        final faseActual = _normalizarFase(state.faseActual);
        final esFortificacion = faseActual == 'fortificacion';
        final esVecinoDelOrigen =
            vecinosDelNodoTocado?.contains(state.origenSeleccionado) ?? false;

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

    if (!_puedeSeleccionarseComoOrigen(id, jugadorLocalId)) {
      return;
    }

    

    final graphService = await ref.read(graphServiceProvider.future);
    final resaltadas = _calcularComarcasResaltadasSegunFase(id, graphService);

    state = state.copyWith(
      origenSeleccionado: id,
      clearDestino: true,
      esperandoDestino: false,
      comarcasResaltadas: resaltadas,
    );
  }

  Set<String> _calcularComarcasResaltadasSegunFase(String comarcaId, GraphService graphService) {
    final territorioOrigen = state.mapa[comarcaId];
    if (territorioOrigen == null) return <String>{};

    final ownerOrigen = territorioOrigen.ownerId;
    final tropasOrigen = territorioOrigen.units;

    final vecinas = graphService.obtenerComarcasEnRango(comarcaId, 1);

    switch (state.faseActual.toUpperCase()) {
      case 'REFUERZO':
        return <String>{};

      case 'GESTION':
        return <String>{};

      case 'ATAQUE_CONVENCIONAL':
        if (ownerOrigen.isEmpty || tropasOrigen <= 1) return <String>{};

        return vecinas.where((vecinaId) {
          final territorioVecino = state.mapa[vecinaId];
          if (territorioVecino == null) return false;

          final ownerVecino = territorioVecino.ownerId;
          if (ownerVecino.isEmpty) return false;

          return ownerVecino != ownerOrigen;
        }).toSet();

      case 'FORTIFICACION':
        return vecinas.where((vecinaId) {
          final territorioVecino = state.mapa[vecinaId];
          if (territorioVecino == null) return false;

          final ownerVecino = territorioVecino.ownerId;
          if (ownerVecino.isEmpty) return false;

          return ownerVecino == ownerOrigen;
        }).toSet();

      default:
        return vecinas;
    }
  }

  void prepararAtaque() {
    if (state.origenSeleccionado == null) return;

    state = state.copyWith(esperandoDestino: true, clearDestino: true);
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

  void toggleVistaRegiones() {
    // Cambio rapido entre vista tactica (comarcas) y vista territorial (regiones).
    state = state.copyWith(vistaRegiones: !state.vistaRegiones);
  }

  void actualizarTerritorio({
    required String territorioId,
    required int units,
  }) {
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
final gameProvider = NotifierProvider<GameNotifier, GameState>(
  () => GameNotifier(),
);
