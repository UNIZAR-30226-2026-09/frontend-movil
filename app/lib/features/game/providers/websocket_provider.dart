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

  WebSocketState({
    this.isConnected = false,
    this.currentPartidaId,
    this.versionEventoSistema = 0,
    this.tipoEventoSistema,
    this.jugadorEventoSistema,
    this.ganadorEventoSistema,
    this.mensajeEventoSistema,
    this.payloadEventoSistema,
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
    bool clearCurrentPartidaId = false,
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
      dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.49:8000/api/v1';
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

            // Eventos de sistema para UI
            if (tipoEvento == 'JUGADOR_ELIMINADO' ||
                tipoEvento == 'FIN_PARTIDA' ||
              tipoEvento == 'VOTACION_PAUSA_INICIADA' ||
              tipoEvento == 'PAUSA_RECHAZADA' ||
              tipoEvento == 'PAUSA_APROBADA') {
              final rawPayload = data['payload'];
              final payload = rawPayload is Map<String, dynamic>
                  ? rawPayload
                  : (rawPayload is Map
                        ? Map<String, dynamic>.from(rawPayload)
                        : data);

              state = state.copyWith(
                tipoEventoSistema: tipoEvento.toString(),
                jugadorEventoSistema:
                    (payload['jugador_solicitante'] ?? data['jugador'])
                        ?.toString(),
                ganadorEventoSistema:
                    (data['ganador'] ?? data['jugador_ganador'])?.toString(),
                mensajeEventoSistema:
                    (payload['mensaje'] ?? data['mensaje'])?.toString(),
                payloadEventoSistema: payload,
                versionEventoSistema: state.versionEventoSistema + 1,
              );
              return;
            }

            // --- ATAQUE_RESULTADO ---
            // Registramos para el popup Y actualizamos tropas de ambos territorios.
            // NO cambiamos el dueño aquí — el evento es broadcast y no incluye
            // el atacante, así que el cambio de owner lo dejamos para MOVIMIENTO_CONQUISTA.
            if (tipoEvento == 'ATAQUE_RESULTADO') {
              ref.read(gameProvider.notifier).registrarResultadoAtaque(data);

              final origen = data['origen'] as String?;
              final destino = data['destino'] as String?;
              final tropasOrigen = data['tropas_restantes_origen'] as int?;
              final tropasDestino = data['tropas_restantes_defensor'] as int?;

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
            }

            // --- MOVIMIENTO_CONQUISTA ---
            // Aquí sí tenemos el jugador correcto en el payload — cambiamos dueño y tropas.
            // Lo procesamos quirúrgicamente y NO lo dejamos pasar al bloque genérico de abajo.
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
                // Al mover la conquista el destino ya es nuestro — usamos el jugador del payload
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
              // Salimos — no dejamos que este evento entre al bloque genérico
              return;
            }

            // --- TROPAS_COLOCADAS ---
            // Actualización quirúrgica de un territorio — igual que MOVIMIENTO_CONQUISTA,
            // lo procesamos aquí y no lo dejamos pasar al bloque genérico.
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

              // Además descontamos la reserva del jugador que acaba de colocar.
              // Esto hace que el HUD de tropas se refresque al momento.
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
                final resumen = nivel > 0
                    ? '$ramaLabel Nivel $nivel'
                    : ramaLabel;
                ref
                    .read(gameProvider.notifier)
                    .registrarInvestigacionCompletadaDesdeWs(resumen);
              }
              return;
            }

            // --- NUEVO_JUGADOR ---
            if (tipoEvento == 'NUEVO_JUGADOR') {
              final username = data['jugador'] as String?;
              if (username != null) {
                ref.read(gameProvider.notifier).agregarJugador(username);
              }
              return;
            }

            if (tipoEvento == 'CAMBIO_FASE') {
              // Algunos backends lo envían directo y otros anidado en payload.
              // Unificamos la lectura para no perder nueva_fase/jugador_activo.
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
                // Fallback: si llega un shape incompleto, mantenemos la vía genérica.
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
                  );
              return;
            }

            // --- Eventos de estado global (fase, turno, mapa completo) ---
            // Solo estos tres eventos pasan por actualizarDesdeServidor.
            // El bloque genérico de 'mapa'/'fase_actual' lo quitamos para evitar
            // dobles actualizaciones en eventos que ya procesamos arriba.
            if (tipoEvento == 'ACTUALIZACION_MAPA' ||
                tipoEvento == 'PARTIDA_INICIADA') {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
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
