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

            // Resultado de un ataque — lo registramos aparte para mostrar el popup de dados
            if (tipoEvento == 'ATAQUE_RESULTADO') {
              ref.read(gameProvider.notifier).registrarResultadoAtaque(data);
            }

            // Eventos que actualizan fase, turno o el mapa completo
            if (tipoEvento == 'CAMBIO_FASE' ||
                tipoEvento == 'ACTUALIZACION_MAPA' ||
                tipoEvento == 'PARTIDA_INICIADA') {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
            }

            // Si el JSON trae mapa o fase aunque no sea uno de los eventos anteriores,
            // actualizamos igualmente — por si el backend manda algo inesperado
            if (data.containsKey('mapa') || data.containsKey('fase_actual')) {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
            }

            // TROPAS_COLOCADAS solo actualiza un territorio y la reserva del jugador.
            // No manda el mapa completo así que actualizamos quirúrgicamente en vez de
            // llamar a actualizarDesdeServidor que machaca todo.
            if (tipoEvento == 'TROPAS_COLOCADAS') {
              ref.read(gameProvider.notifier).actualizarTerritorio(
                territorioId: data['territorio'] as String,
                units: data['tropas_totales_ahora'] as int,
              );
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
}

final webSocketProvider = NotifierProvider<WebSocketNotifier, WebSocketState>(
  () => WebSocketNotifier(),
);