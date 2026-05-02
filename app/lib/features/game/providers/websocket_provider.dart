import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/api/websocket_service.dart';
import 'game_provider.dart';

class WebSocketState {
  final bool isConnected;
  final int? currentPartidaId;
  final int versionEventoSistema;
  final String? tipoEventoSistema;
  final String? jugadorEventoSistema;
  final String? ganadorEventoSistema;
  final String? mensajeEventoSistema;
  final Map<String, dynamic>? payloadEventoSistema;

  // Progreso de la votación de pausa en curso.
  final int? votosAFavor;
  final int? totalJugadores;

  WebSocketState({
    this.isConnected = false,
    this.currentPartidaId,
    this.versionEventoSistema = 0,
    this.tipoEventoSistema,
    this.jugadorEventoSistema,
    this.ganadorEventoSistema,
    this.mensajeEventoSistema,
    this.payloadEventoSistema,
    this.votosAFavor,
    this.totalJugadores,
  });

  WebSocketState copyWith({
    bool? isConnected,
    int? currentPartidaId,
    int? versionEventoSistema,
    String? tipoEventoSistema,
    String? jugadorEventoSistema,
    String? ganadorEventoSistema,
    String? mensajeEventoSistema,
    Map<String, dynamic>? payloadEventoSistema,
    int? votosAFavor,
    int? totalJugadores,
    bool clearCurrentPartidaId = false,
    bool clearVotacion = false,
  }) {
    return WebSocketState(
      isConnected: isConnected ?? this.isConnected,
      currentPartidaId: clearCurrentPartidaId
          ? null
          : (currentPartidaId ?? this.currentPartidaId),
      versionEventoSistema: versionEventoSistema ?? this.versionEventoSistema,
      tipoEventoSistema: tipoEventoSistema ?? this.tipoEventoSistema,
      jugadorEventoSistema: jugadorEventoSistema ?? this.jugadorEventoSistema,
      ganadorEventoSistema: ganadorEventoSistema ?? this.ganadorEventoSistema,
      mensajeEventoSistema: mensajeEventoSistema ?? this.mensajeEventoSistema,
      payloadEventoSistema: payloadEventoSistema ?? this.payloadEventoSistema,
      // clearVotacion resetea el marcador cuando la pausa termina (aprobada o rechazada).
      votosAFavor: clearVotacion ? null : (votosAFavor ?? this.votosAFavor),
      totalJugadores:
          clearVotacion ? null : (totalJugadores ?? this.totalJugadores),
    );
  }
}

class WebSocketNotifier extends Notifier<WebSocketState> {
  late WebSocketService _wsService;
  AppLifecycleListener? _lifecycleListener;
  int? _currentPartidaId;

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  WebSocketState build() {
    final baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://soberania.dev/api/v1';
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    _wsService = WebSocketService(baseUrl: wsUrl);

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        debugPrint('📱 App en Segundo Plano -> Cortando WS');
        _wsService.disconnect();
        state = state.copyWith(
          isConnected: false,
          currentPartidaId: _currentPartidaId,
        );
      },
      onResume: () {
        debugPrint('📱 App en Primer Plano -> Recuperando WS');
        if (_currentPartidaId != null) {
          _reconnect();
        }
      },
    );

    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _wsService.disconnect();
    });

    return WebSocketState(isConnected: false);
  }

  Future<void> connectToPartida(int partidaId) async {
    _currentPartidaId = partidaId;
    state = state.copyWith(
      isConnected: state.isConnected,
      currentPartidaId: _currentPartidaId,
    );
    await _reconnect();
  }

  Future<void> _reconnect() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null && user.username.isNotEmpty && _currentPartidaId != null) {
      _wsService.disconnect();
      _wsService.connect(user.username, _currentPartidaId!);
      state = state.copyWith(
        isConnected: true,
        currentPartidaId: _currentPartidaId,
      );

      _wsService.stream?.listen(
        (message) {
          debugPrint('📩 Evento WS recibido: $message');
          try {
            final data = jsonDecode(message);
            if (data is! Map<String, dynamic>) return;

            final tipoEvento = data['tipo_evento']?.toString();

            // ── Eventos que la UI consume como notificaciones de sistema ──────────
            // Cualquier pantalla puede escuchar versionEventoSistema para reaccionar.
            if (tipoEvento == 'JUGADOR_ELIMINADO' ||
                tipoEvento == 'FIN_PARTIDA' ||
                tipoEvento == 'SOLICITUD_PAUSA' ||
                tipoEvento == 'PAUSA_RECHAZADA' ||
                tipoEvento == 'PARTIDA_PAUSADA') {
              final rawPayload = data['payload'];
              final payload = rawPayload is Map<String, dynamic>
                  ? rawPayload
                  : (rawPayload is Map
                        ? Map<String, dynamic>.from(rawPayload)
                        : data);

              // Al resolver la pausa (aprobada o rechazada) limpiamos el marcador.
              final esFinVotacion =
                  tipoEvento == 'PARTIDA_PAUSADA' ||
                  tipoEvento == 'PAUSA_RECHAZADA';

              state = state.copyWith(
                tipoEventoSistema: tipoEvento,
                jugadorEventoSistema:
                    (payload['solicitante'] ??
                            payload['jugador_solicitante'] ??
                            data['jugador'])
                        ?.toString(),
                ganadorEventoSistema:
                    (data['ganador'] ?? data['jugador_ganador'])?.toString(),
                mensajeEventoSistema:
                    (payload['mensaje'] ?? data['mensaje'])?.toString(),
                payloadEventoSistema: payload,
                versionEventoSistema: state.versionEventoSistema + 1,
                clearVotacion: esFinVotacion,
              );
              return;
            }

            // ── VOTO_PAUSA — actualiza el marcador de votos sin disparar popup ──
            if (tipoEvento == 'VOTO_PAUSA') {
              final rawPayload = data['payload'];
              final payload = rawPayload is Map
                  ? Map<String, dynamic>.from(rawPayload)
                  : data;

              // El backend puede mandar los contadores dentro del payload o en la raíz.
              final votosAFavor =
                  _toInt(payload['votos_a_favor'] ?? data['votos_a_favor']);
              final totalJugadores =
                  _toInt(payload['total_jugadores'] ?? data['total_jugadores']);

              // También lo subimos como evento de sistema para que la UI pueda
              // mostrar el progreso ("X/Y votos") si lo necesita.
              state = state.copyWith(
                tipoEventoSistema: tipoEvento,
                jugadorEventoSistema:
                    (payload['votante'] ?? data['votante'])?.toString(),
                payloadEventoSistema: payload,
                votosAFavor: votosAFavor,
                totalJugadores: totalJugadores,
                versionEventoSistema: state.versionEventoSistema + 1,
              );
              return;
            }

            // ── PARTIDA_REANUDADA — el host reanudó, volvemos al juego ──────────
            if (tipoEvento == 'PARTIDA_REANUDADA') {
              final rawPayload = data['payload'];
              final payload = rawPayload is Map
                  ? Map<String, dynamic>.from(rawPayload)
                  : data;

              final nuevaFase = payload['nueva_fase']?.toString();
              final jugadorActivo = payload['jugador_activo']?.toString();

              // Actualizamos la fase en el gameProvider para que la batalla_screen
              // pueda arrancar correctamente tras la reanudación.
              if (nuevaFase != null && jugadorActivo != null) {
                ref
                    .read(gameProvider.notifier)
                    .actualizarCambioFaseDesdeWs(
                      nuevaFase: nuevaFase,
                      jugadorActivo: jugadorActivo,
                      tropasRecibidas: 0,
                      finFaseUtc: payload['fin_fase_utc']?.toString(),
                      usarDuracionCompleta: false,
                    );
              }

              state = state.copyWith(
                tipoEventoSistema: tipoEvento,
                payloadEventoSistema: payload,
                versionEventoSistema: state.versionEventoSistema + 1,
                clearVotacion: true,
              );
              return;
            }

            // ── ATAQUE_RESULTADO ──────────────────────────────────────────────────
            if (tipoEvento == 'ATAQUE_RESULTADO') {
              final origen = data['origen'] as String?;
              final destino = data['destino'] as String?;
              final tropasOrigen = data['tropas_restantes_origen'] as int?;
              final tropasDestino = data['tropas_restantes_defensor'] as int?;
              final gameState = ref.read(gameProvider);
              final esAtaquePendienteLocal =
                  origen != null &&
                  destino != null &&
                  gameState.ataquePendienteOrigen == origen &&
                  gameState.ataquePendienteDestino == destino;

              if (esAtaquePendienteLocal) {
                ref.read(gameProvider.notifier).registrarResultadoAtaque(data);
                ref.read(gameProvider.notifier).limpiarAtaquePendiente();
                ref.read(gameProvider.notifier).cancelarAtaque();
              }

              if (origen != null && tropasOrigen != null) {
                ref
                    .read(gameProvider.notifier)
                    .actualizarTerritorio(
                      territorioId: origen,
                      units: tropasOrigen,
                    );
              }
              // Solo actualizamos unidades del destino — el dueño lo cambia MOVIMIENTO_CONQUISTA
              if (destino != null && tropasDestino != null) {
                ref
                    .read(gameProvider.notifier)
                    .actualizarTerritorio(
                      territorioId: destino,
                      units: tropasDestino,
                    );
              }
              return;
            }

            // ── MOVIMIENTO_CONQUISTA ──────────────────────────────────────────────
            // Aquí sí tenemos el jugador correcto en el payload — cambiamos dueño y tropas.
            if (tipoEvento == 'MOVIMIENTO_CONQUISTA') {
              final origen = data['origen'] as String?;
              final destino = data['destino'] as String?;
              final tropas = data['tropas'] as int? ?? 0;
              final jugador = data['jugador'] as String?;

              if (origen != null && destino != null) {
                final mapaActual = ref.read(gameProvider).mapa;
                final tropasOrigen = (mapaActual[origen]?.units ?? 0) - tropas;
                final tropasDestino =
                    (mapaActual[destino]?.units ?? 0) + tropas;

                ref
                    .read(gameProvider.notifier)
                    .actualizarTerritorio(
                      territorioId: origen,
                      units: tropasOrigen,
                    );
                if (jugador != null) {
                  ref
                      .read(gameProvider.notifier)
                      .actualizarTerritorioConDueno(
                        territorioId: destino,
                        units: tropasDestino,
                        nuevoOwner: jugador,
                      );
                } else {
                  ref
                      .read(gameProvider.notifier)
                      .actualizarTerritorio(
                        territorioId: destino,
                        units: tropasDestino,
                      );
                }
              }
              ref.read(gameProvider.notifier).limpiarSeleccionCombate();
              return;
            }

            // ── TROPAS_COLOCADAS ──────────────────────────────────────────────────
            if (tipoEvento == 'TROPAS_COLOCADAS') {
              final territorioId = data['territorio']?.toString();
              final tropasTotalesAhora = _toInt(data['tropas_totales_ahora']);

              if (territorioId != null && tropasTotalesAhora != null) {
                ref
                    .read(gameProvider.notifier)
                    .actualizarTerritorio(
                      territorioId: territorioId,
                      units: tropasTotalesAhora,
                    );
              }

              // Descontamos la reserva del jugador que acaba de colocar.
              final jugador = data['jugador']?.toString();
              final tropasColocadas =
                  _toInt(data['tropas_añadidas']) ??
                  _toInt(data['tropas_anadidas']) ??
                  _toInt(data['tropas']) ??
                  0;

              if (jugador != null &&
                  jugador.isNotEmpty &&
                  tropasColocadas > 0) {
                ref
                    .read(gameProvider.notifier)
                    .restarTropasReserva(
                      jugadorId: jugador,
                      tropas: tropasColocadas,
                    );
              }
              return;
            }

            // ── TRABAJO_COMPLETADO ────────────────────────────────────────────────
            if (tipoEvento == 'TRABAJO_COMPLETADO') {
              // El backend manda: usuario_id, territorio_id, ganancia.
              // No hay payload anidado para este evento.
              final jugador = data['usuario_id']?.toString() ?? '';
              final monedasGanadas = _toInt(data['ganancia']) ?? 0;

              if (jugador.isNotEmpty && monedasGanadas > 0) {
                ref
                    .read(gameProvider.notifier)
                    .registrarTrabajoCompletadoDesdeWs(
                      jugadorId: jugador,
                      monedasGanadas: monedasGanadas,
                      monedasTotales: null,
                    );
              }
              return;
            }

            // ── INVESTIGACION_COMPLETADA ──────────────────────────────────────────
            if (tipoEvento == 'INVESTIGACION_COMPLETADA') {
              final rawPayload = data['payload'];
              final payload = rawPayload is Map
                  ? Map<String, dynamic>.from(rawPayload)
                  : data;

              final ramaRaw =
                  (payload['rama'] ??
                          payload['branch'] ??
                          payload['linea'] ??
                          payload['tipo'])
                      ?.toString() ??
                  '';
              final nivel =
                  _toInt(payload['nivel']) ??
                  _toInt(payload['level']) ??
                  _toInt(payload['nivel_actual']) ??
                  0;

              String ramaLabel;
              switch (ramaRaw.trim().toLowerCase()) {
                case 'artilleria':
                  ramaLabel = 'Artillería';
                  break;
                case 'biologica':
                  ramaLabel = 'Biológica';
                  break;
                case 'logistica':
                  ramaLabel = 'Logística';
                  break;
                default:
                  ramaLabel = ramaRaw.trim();
              }

              if (ramaLabel.isNotEmpty) {
                final resumen =
                    nivel > 0 ? '$ramaLabel Nivel $nivel' : ramaLabel;
                ref
                    .read(gameProvider.notifier)
                    .registrarInvestigacionCompletadaDesdeWs(resumen);
              }
              return;
            }

            // ── NUEVO_JUGADOR ─────────────────────────────────────────────────────
            if (tipoEvento == 'NUEVO_JUGADOR') {
              final username = data['jugador'] as String?;
              if (username != null) {
                ref.read(gameProvider.notifier).agregarOActualizarJugador(
                  username: username,
                  avatar: data['avatar']?.toString(),
                );
              }
              return;
            }

            // ── CAMBIO_FASE ───────────────────────────────────────────────────────
            if (tipoEvento == 'CAMBIO_FASE') {
              // Algunos backends lo envían directo y otros anidado en payload.
              final rawPayload = data['payload'];
              final payload = rawPayload is Map
                  ? Map<String, dynamic>.from(rawPayload)
                  : data;

              final nuevaFase = payload['nueva_fase']?.toString();
              final jugadorActivo = payload['jugador_activo']?.toString();
              final tropasRecibidasRaw = payload['tropas_recibidas'];
              final tropasRecibidas = tropasRecibidasRaw is int
                  ? tropasRecibidasRaw
                  : (tropasRecibidasRaw is num
                        ? tropasRecibidasRaw.toInt()
                        : int.tryParse(tropasRecibidasRaw?.toString() ?? '') ??
                              0);

              if (nuevaFase == null || jugadorActivo == null) {
                ref
                    .read(gameProvider.notifier)
                    .actualizarDesdeServidor(payload);
                return;
              }

              ref
                  .read(gameProvider.notifier)
                  .actualizarCambioFaseDesdeWs(
                    nuevaFase: nuevaFase,
                    jugadorActivo: jugadorActivo,
                    tropasRecibidas: tropasRecibidas,
                    finFaseUtc: payload['fin_fase_utc']?.toString(),
                  );
              return;
            }

            // ── Eventos de estado global (mapa completo) ──────────────────────────
            if (tipoEvento == 'ACTUALIZACION_MAPA') {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
            }

            if (tipoEvento == 'PARTIDA_INICIADA') {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
              state = state.copyWith(
                tipoEventoSistema: tipoEvento,
                versionEventoSistema: state.versionEventoSistema + 1,
              );
              return;
            }
          } catch (e) {
            debugPrint('⚠️ Error parseando el JSON del WebSocket: $e');
          }
        },
        onDone: () {
          debugPrint('⭕ Stream del WS cerrado por el servidor.');
          state = state.copyWith(
            isConnected: false,
            currentPartidaId: _currentPartidaId,
          );
          _wsService.disconnect();
        },
        onError: (e) {
          debugPrint('🔴 Error en Stream WS: $e');
          state = state.copyWith(
            isConnected: false,
            currentPartidaId: _currentPartidaId,
          );
          _wsService.disconnect();
        },
        cancelOnError: true,
      );
    } else {
      debugPrint(
        '⚠️ Intento de conexión WS fallido: No hay usuario en memoria.',
      );
    }
  }

  void emitirEvento(String tipoEvento, Map<String, dynamic> datos) {
    final payloadParaFastAPI = {'accion': tipoEvento, ...datos};
    _wsService.sendEvent(tipoEvento, payloadParaFastAPI);
  }

  void disconnect() {
    _wsService.disconnect();
    state = state.copyWith(isConnected: false, clearCurrentPartidaId: true);
    _currentPartidaId = null;
  }
}

final webSocketProvider = NotifierProvider<WebSocketNotifier, WebSocketState>(
  () => WebSocketNotifier(),
);
