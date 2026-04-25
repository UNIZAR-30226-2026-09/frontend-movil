import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../auth/providers/auth_provider.dart';

class GlobalWebSocketState {
  final bool isConnected;
  final String? username;

  const GlobalWebSocketState({
    this.isConnected = false,
    this.username,
  });

  GlobalWebSocketState copyWith({
    bool? isConnected,
    String? username,
  }) {
    return GlobalWebSocketState(
      isConnected: isConnected ?? this.isConnected,
      username: username ?? this.username,
    );
  }
}

class GlobalWebSocketNotifier extends Notifier<GlobalWebSocketState> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  @override
  GlobalWebSocketState build() {
    ref.listen(authProvider, (previous, next) {
      final username = next.user?.username;

      if (username != null && username.isNotEmpty && !state.isConnected) {
        _connect(username);
      } else if (username == null && state.isConnected) {
        _disconnect();
        state = const GlobalWebSocketState(isConnected: false);
      }
    });

    ref.onDispose(_disconnect);

    final initialUsername = ref.read(authProvider).user?.username;
    if (initialUsername != null && initialUsername.isNotEmpty) {
      Future.microtask(() => _connect(initialUsername));
    }

    return const GlobalWebSocketState(isConnected: false);
  }

  void _connect(String username) {
    if (_channel != null && state.username == username && state.isConnected) {
      return;
    }

    _disconnect();

    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://soberania.dev/api/v1';
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    final url = '$wsUrl/global/$username';
    final uri = Uri.parse(url);

    debugPrint('🌐 WS Global -> Intentando conectar a: $url');

    try {
      _channel = WebSocketChannel.connect(uri);
      state = state.copyWith(isConnected: true, username: username);
      debugPrint('🟢 WS Global conectado: $url');

      _subscription = _channel!.stream.listen(
        (message) {
          debugPrint('🌐 WS Global recibido: $message');
        },
        onError: (error) {
          debugPrint('🔴 Error WS Global: $error');
          state = state.copyWith(isConnected: false);
          _disconnect();
        },
        onDone: () {
          debugPrint('⭕ WS Global desconectado');
          state = state.copyWith(isConnected: false);
          _disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('🔴 No se pudo conectar WS Global: $e');
      state = state.copyWith(isConnected: false);
      _disconnect();
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}

final globalWebSocketProvider =
    NotifierProvider<GlobalWebSocketNotifier, GlobalWebSocketState>(
  GlobalWebSocketNotifier.new,
);
