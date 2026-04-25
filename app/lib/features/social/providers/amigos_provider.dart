import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/api/dio_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../amigos/providers/global_websocket_provider.dart';
import '../models/amistad_model.dart';
import '../models/estado_amistad.dart';
import '../services/amigos_service.dart';

final amigosServiceProvider = Provider<AmigosService>((ref) {
  final dio = ref.read(dioProvider);
  return AmigosService(dio);
});

class AmigosState {
  final List<AmistadModel> amigos;
  final List<AmistadModel> solicitudes;
  final bool isLoading;
  final bool isSendingRequest;
  final String? errorMessage;

  const AmigosState({
    this.amigos = const [],
    this.solicitudes = const [],
    this.isLoading = false,
    this.isSendingRequest = false,
    this.errorMessage,
  });

  AmigosState copyWith({
    List<AmistadModel>? amigos,
    List<AmistadModel>? solicitudes,
    bool? isLoading,
    bool? isSendingRequest,
    Object? errorMessage = _noChange,
  }) {
    return AmigosState(
      amigos: amigos ?? this.amigos,
      solicitudes: solicitudes ?? this.solicitudes,
      isLoading: isLoading ?? this.isLoading,
      isSendingRequest: isSendingRequest ?? this.isSendingRequest,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _noChange = Object();

class AmigosNotifier extends StateNotifier<AmigosState> {
  final AmigosService service;
  final String usuarioActual;

  Timer? _pollingTimer;
  bool _isRefreshing = false;

  AmigosNotifier({
    required this.service,
    required this.usuarioActual,
  }) : super(const AmigosState());

  String _nombreDelAmigo(AmistadModel amistad) {
    return amistad.otroUsuario(usuarioActual);
  }

  List<AmistadModel> _aplicarEstadosConexion(
    List<AmistadModel> amigos,
    Map<String, String> estadosConexion,
  ) {
    return amigos.map((amistad) {
      final nombreAmigo = _nombreDelAmigo(amistad);
      final estadoConexion = estadosConexion[nombreAmigo];

      if (estadoConexion == null) {
        return amistad.copyWith(estadoConexion: 'DESCONECTADO');
      }

      return amistad.copyWith(estadoConexion: estadoConexion);
    }).toList();
  }

  List<AmistadModel> _actualizarAmigoPorNombre(
    List<AmistadModel> amigos,
    String nombreAmigo,
    String estadoConexion,
  ) {
    return amigos.map((amistad) {
      if (_nombreDelAmigo(amistad) != nombreAmigo) {
        return amistad;
      }

      return amistad.copyWith(estadoConexion: estadoConexion);
    }).toList();
  }

  Future<Map<String, String>> _cargarEstadosConexion() async {
    try {
      final response = await service.dio.get('/amigos/activos');
      final data = response.data;

      if (data is! List) return const {};

      return {
        for (final item in data)
          if (item is Map)
            item['username']?.toString() ?? '':
                item['estado_conexion']?.toString() ?? 'DESCONECTADO',
      }..removeWhere((key, value) => key.isEmpty);
    } catch (_) {
      return const {};
    }
  }

  void procesarEventoPresencia(Map<String, dynamic> event) {
    final tipoEvento = event['tipo_evento']?.toString();
    if (tipoEvento != 'PRESENCIA') return;

    final nombreAmigo = event['username']?.toString();
    final estado = event['estado']?.toString();

    if (nombreAmigo == null || nombreAmigo.isEmpty) return;
    if (estado == null || estado.isEmpty) return;

    final estadoConexion = estado.toUpperCase() == 'ONLINE'
        ? 'online'
        : 'DESCONECTADO';

    state = state.copyWith(
      amigos: _actualizarAmigoPorNombre(
        state.amigos,
        nombreAmigo,
        estadoConexion,
      ),
    );
  }

  List<AmistadModel> get solicitudesRecibidas {
    if (usuarioActual.isEmpty) return [];

    return state.solicitudes.where((s) {
      if (s.estado != EstadoAmistad.pendiente) return false;

      // Caso normal: user_2 soy yo.
      if (s.recibidaPorMi(usuarioActual)) return true;

      // Caso compatible con web: el backend ya devuelve solo solicitudes recibidas.
      // Si user_1 no soy yo, la tratamos como recibida.
      if (s.user1.isNotEmpty && !s.enviadaPorMi(usuarioActual)) return true;

      return false;
    }).toList();
  }

  List<AmistadModel> get solicitudesEnviadas {
    if (usuarioActual.isEmpty) return [];

    return state.solicitudes.where((s) {
      if (s.estado != EstadoAmistad.pendiente) return false;
      return s.enviadaPorMi(usuarioActual);
    }).toList();
  }

  void iniciarPolling() {
    if (usuarioActual.isEmpty) return;

    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refrescarSilencioso(),
    );
  }

  Future<void> cargarDatos() async {
    if (usuarioActual.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final results = await Future.wait([
        service.listarAmigos(),
        service.listarSolicitudes(),
      ]);
      final estadosConexion = await _cargarEstadosConexion();

      if (!mounted) return;

      state = state.copyWith(
        amigos: _aplicarEstadosConexion(results[0], estadosConexion),
        solicitudes: results[1],
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar la información de amigos',
      );
    }
  }

  Future<void> refrescarSilencioso() async {
    if (usuarioActual.isEmpty) return;
    if (_isRefreshing) return;
  
    _isRefreshing = true;
  
    try {
      final results = await Future.wait([
        service.listarAmigos(),
        service.listarSolicitudes(),
      ]);
      final estadosConexion = await _cargarEstadosConexion();
  
      if (!mounted) return;
  
      state = state.copyWith(
        amigos: _aplicarEstadosConexion(results[0], estadosConexion),
        solicitudes: results[1],
      );
    } catch (_) {
      // En polling no mostramos error para no molestar al usuario cada 5 segundos.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> enviarSolicitud(String user2) async {
    final user2Limpio = user2.trim();

    if (usuarioActual.isEmpty) return false;
    if (user2Limpio.isEmpty) return false;

    state = state.copyWith(
      isSendingRequest: true,
      errorMessage: null,
    );

    try {
      await service.solicitarAmistad(user2Limpio);

      if (!mounted) return false;

      state = state.copyWith(isSendingRequest: false);

      await refrescarSilencioso();

      return true;
    } on DioException catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        isSendingRequest: false,
        errorMessage: _mensajeDesdeDio(e, 'No se pudo enviar la solicitud de amistad'),
      );

      return false;
    } catch (_) {
      if (!mounted) return false;

      state = state.copyWith(
        isSendingRequest: false,
        errorMessage: 'No se pudo enviar la solicitud de amistad',
      );

      return false;
    }
  }

  Future<void> aceptarSolicitud(int solicitudId) async {
    if (usuarioActual.isEmpty) return;

    try {
      await service.procesarSolicitud(
        solicitudId: solicitudId,
        estado: EstadoAmistad.aceptada,
      );

      await refrescarSilencioso();
    } on DioException catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: _mensajeDesdeDio(e, 'No se pudo aceptar la solicitud'),
      );
    } catch (_) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: 'No se pudo aceptar la solicitud',
      );
    }
  }

  Future<void> rechazarSolicitud(int solicitudId) async {
    if (usuarioActual.isEmpty) return;

    try {
      await service.procesarSolicitud(
        solicitudId: solicitudId,
        estado: EstadoAmistad.rechazada,
      );

      await refrescarSilencioso();
    } on DioException catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: _mensajeDesdeDio(e, 'No se pudo rechazar la solicitud'),
      );
    } catch (_) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: 'No se pudo rechazar la solicitud',
      );
    }
  }

  Future<void> eliminarAmigo(int amigoId) async {
    if (usuarioActual.isEmpty) return;

    try {
      await service.eliminarAmigo(amigoId);
      await refrescarSilencioso();
    } on DioException catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: _mensajeDesdeDio(e, 'No se pudo eliminar el amigo'),
      );
    } catch (_) {
      if (!mounted) return;

      state = state.copyWith(
        errorMessage: 'No se pudo eliminar el amigo',
      );
    }
  }

  void limpiarError() {
    state = state.copyWith(errorMessage: null);
  }

  String _mensajeDesdeDio(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];

      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        return detail.toString();
      }
    }

    return fallback;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    super.dispose();
  }
}

final amigosProvider =
    StateNotifierProvider.autoDispose<AmigosNotifier, AmigosState>((ref) {
  final service = ref.read(amigosServiceProvider);
  final authState = ref.watch(authProvider);

  final usuarioActual = authState.user?.username;

  final notifier = AmigosNotifier(
    service: service,
    usuarioActual: usuarioActual ?? '',
  );

  ref.listen(globalWebSocketProvider, (previous, next) {
    final event = next.lastEvent;
    if (event == null) return;
    notifier.procesarEventoPresencia(Map<String, dynamic>.from(event));
  });

  if (usuarioActual == null || usuarioActual.isEmpty) {
    return notifier;
  }

  notifier.cargarDatos();
  notifier.iniciarPolling();

  return notifier;
});