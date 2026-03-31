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

  WebSocketState({
    this.isConnected = false,
    this.currentPartidaId,
  });
}

class WebSocketNotifier extends Notifier<WebSocketState> {
  late WebSocketService _wsService;
  AppLifecycleListener? _lifecycleListener;
  int? _currentPartidaId;

  @override
  WebSocketState build() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'ws://127.0.0.1:8000/api/v1';
    _wsService = WebSocketService(baseUrl: baseUrl);

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        debugPrint('📱 App en Segundo Plano -> Cortando WS');
        _wsService.disconnect();
        state = WebSocketState(isConnected: false, currentPartidaId: _currentPartidaId);
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
    state = WebSocketState(isConnected: state.isConnected, currentPartidaId: _currentPartidaId);
    await _reconnect();
  }

  Future<void> _reconnect() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null && user.username.isNotEmpty && _currentPartidaId != null) {
      _wsService.disconnect();
      _wsService.connect(user.username, _currentPartidaId!);
      state = WebSocketState(isConnected: true, currentPartidaId: _currentPartidaId);

      _wsService.stream?.listen(
        (message) {
          debugPrint('📩 Evento WS recibido: $message');
          try {
            final data = jsonDecode(message);
            if (data is! Map<String, dynamic>) return;

            final tipoEvento = data['tipo_evento'];

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
                ref.read(gameProvider.notifier).actualizarTerritorio(
                  territorioId: origen,
                  units: tropasOrigen,
                );
              }
              // Solo actualizamos unidades del destino — el dueño lo cambia MOVIMIENTO_CONQUISTA
              if (destino != null && tropasDestino != null) {
                ref.read(gameProvider.notifier).actualizarTerritorio(
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
                final tropasDestino = (mapaActual[destino]?.units ?? 0) + tropas;

                ref.read(gameProvider.notifier).actualizarTerritorio(
                  territorioId: origen,
                  units: tropasOrigen,
                );
                // Al mover la conquista el destino ya es nuestro — usamos el jugador del payload
                if (jugador != null) {
                  ref.read(gameProvider.notifier).actualizarTerritorioConDueno(
                    territorioId: destino,
                    units: tropasDestino,
                    nuevoOwner: jugador,
                  );
                } else {
                  ref.read(gameProvider.notifier).actualizarTerritorio(
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
              ref.read(gameProvider.notifier).actualizarTerritorio(
                territorioId: data['territorio'] as String,
                units: data['tropas_totales_ahora'] as int,
              );
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

            // --- Eventos de estado global (fase, turno, mapa completo) ---
            // Solo estos tres eventos pasan por actualizarDesdeServidor.
            // El bloque genérico de 'mapa'/'fase_actual' lo quitamos para evitar
            // dobles actualizaciones en eventos que ya procesamos arriba.
            if (tipoEvento == 'CAMBIO_FASE' ||
                tipoEvento == 'ACTUALIZACION_MAPA' ||
                tipoEvento == 'PARTIDA_INICIADA') {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
            }

          } catch (e) {
            debugPrint('⚠️ Error parseando el JSON del WebSocket: $e');
          }
        },
        onDone: () {
          debugPrint('⭕ Stream del WS cerrado por el servidor.');
          state = WebSocketState(isConnected: false, currentPartidaId: _currentPartidaId);
          _wsService.disconnect();
        },
        onError: (e) {
          debugPrint('🔴 Error en Stream WS: $e');
          state = WebSocketState(isConnected: false, currentPartidaId: _currentPartidaId);
          _wsService.disconnect();
        },
        cancelOnError: true,
      );
    } else {
      debugPrint('⚠️ Intento de conexión WS fallido: No hay usuario en memoria.');
    }
  }

  void emitirEvento(String tipoEvento, Map<String, dynamic> datos) {
    final payloadParaFastAPI = {
      'accion': tipoEvento,
      ...datos,
    };
    _wsService.sendEvent(tipoEvento, payloadParaFastAPI);
  }

  void disconnect() {
    _wsService.disconnect();
    state = WebSocketState(
      isConnected: false,
      currentPartidaId: null,
    );
    _currentPartidaId = null;
  }
}

final webSocketProvider = NotifierProvider<WebSocketNotifier, WebSocketState>(
  () => WebSocketNotifier(),
);