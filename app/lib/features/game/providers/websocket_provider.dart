import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/api/websocket_service.dart';
import 'game_provider.dart';

// El estado que guardaremos (puedes ampliarlo luego con mensajes recibidos)
class WebSocketState {
  final bool isConnected;
  WebSocketState({this.isConnected = false});
}

class WebSocketNotifier extends Notifier<WebSocketState> {
  late WebSocketService _wsService;
  AppLifecycleListener? _lifecycleListener;
  int? _currentPartidaId;

  @override
  WebSocketState build() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'ws://127.0.0.1:8000/api/v1';
    _wsService = WebSocketService(baseUrl: baseUrl);

    // Inicializamos el listener crítico de ciclo de vida (Requisito T47)
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        debugPrint('📱 App en Segundo Plano -> Cortando WS');
        _wsService.disconnect();
        state = WebSocketState(isConnected: false);
      },
      onResume: () {
        debugPrint('📱 App en Primer Plano -> Recuperando WS');
        if (_currentPartidaId != null) {
          _reconnect();
        }
      },
    );

    // Es importante destruir el listener si el provider muere
    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _wsService.disconnect();
    });

    return WebSocketState(isConnected: false);
  }

  /// Función para entrar a la partida por primera vez
  Future<void> connectToPartida(int partidaId) async {
    _currentPartidaId = partidaId;
    await _reconnect();
  }

  Future<void> _reconnect() async {
    // Obtenemos el usuario entero desde el estado de Riverpod
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null && user.username.isNotEmpty && _currentPartidaId != null) {
      // Limpiamos cualquier conexión previa colgada antes de conectar
      _wsService.disconnect();

      _wsService.connect(user.username, _currentPartidaId!);
      state = WebSocketState(isConnected: true);
      
      // Aquí nos suscribimos para escuchar lo que dice el servidor
      _wsService.stream?.listen(
        (message) {
          debugPrint('📩 Evento WS recibido: $message');
          try {
            // Transformamos el string puro en un Mapa de Dart
            final data = jsonDecode(message);
            
            // Si el JSON trae información del mapa o de la partida, actualizamos el estado global
            if (data is Map<String, dynamic> && (data.containsKey('mapa') || data.containsKey('fase_actual'))) {
              ref.read(gameProvider.notifier).actualizarDesdeServidor(data);
            }
          } catch (e) {
            debugPrint('⚠️ Error parseando el JSON del WebSocket: $e');
          }
        },
        onDone: () {
          debugPrint('⭕ Stream del WS cerrado por el servidor.');
          state = WebSocketState(isConnected: false);
          _wsService.disconnect();
        },
        onError: (e) {
          debugPrint('🔴 Error en Stream WS: $e');
          state = WebSocketState(isConnected: false);
          _wsService.disconnect();
        },
        cancelOnError: true,
      );
    } else {
      debugPrint('⚠️ Intento de conexión WS fallido: No hay usuario en memoria.');
    }
  }

  /// Función para que la UI mande un ataque o coloque tropas
  void emitirEvento(String tipoEvento, Map<String, dynamic> datos) {
    // Le inyectamos a la fuerza el campo 'accion' que FastAPI pide a gritos
    final payloadParaFastAPI = {
      'accion': tipoEvento,
      ...datos, // Esparcimos el resto de datos (origen, destino, tropas...)
    };
    
    _wsService.sendEvent(tipoEvento, payloadParaFastAPI);
  }
}

final webSocketProvider = NotifierProvider<WebSocketNotifier, WebSocketState>(
  () => WebSocketNotifier(),
);