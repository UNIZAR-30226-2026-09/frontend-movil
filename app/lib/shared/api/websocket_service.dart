import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String baseUrl;
  
  // Exponemos el stream para que Riverpod lo pueda escuchar
  Stream<dynamic>? get stream => _channel?.stream;

  WebSocketService({required this.baseUrl});

  /// Abre la conexión apuntando al endpoint que espera FastAPI
  void connect(String username, int partidaId) {
    if (_channel != null) return; // Evita conexiones duplicadas

    // Fuerza bruta para asegurar que usamos el protocolo WebSocket
    String wsUrl = baseUrl;
    if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    }

    // Montamos la URL final con el formato /ws/{id_partida}/{username}
    final uri = Uri.parse('$wsUrl/ws/$partidaId/$username');

    try {
      _channel = WebSocketChannel.connect(uri);
      debugPrint('🟢 WebSocket Conectado a $uri'); 
    } catch (e) {
      debugPrint('🔴 Error al conectar WebSocket: $e');
    }
  }

  /// Envía un JSON puro al servidor (El Camarero)
  void sendEvent(String tipoEvento, Map<String, dynamic> payload) {
    if (_channel != null) {
      final message = jsonEncode({
        "tipo_evento": tipoEvento,
        ...payload,
      });
      _channel!.sink.add(message);
    } else {
      debugPrint('⚠️ Intento de enviar mensaje sin conexión WS');
    }
  }

  /// Cierra el grifo limpiamente y libera el canal
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null; 
      debugPrint('⭕ WebSocket Desconectado y canal liberado');
    }
  }
}