import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/dio_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/estadisticas_model.dart';

final estadisticasProvider = FutureProvider<EstadisticasModel>((ref) async {
  final dio = ref.read(dioProvider);
  final username = ref.read(authProvider).user?.username.trim();

  try {
    final response = await dio.get(
      username == null || username.isEmpty
          ? '/estadisticas/me'
          : '/estadisticas/$username',
    );
    final data = response.data;

    if (data is Map<String, dynamic>) {
      return EstadisticasModel.fromJson(data);
    }

    if (data is Map) {
      return EstadisticasModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Respuesta invalida al cargar estadisticas.');
  } on DioException catch (e) {
    if (username != null && username.isNotEmpty) {
      try {
        final fallbackResponse = await dio.get('/estadisticas/me');
        final fallbackData = fallbackResponse.data;
        if (fallbackData is Map<String, dynamic>) {
          return EstadisticasModel.fromJson(fallbackData);
        }
        if (fallbackData is Map) {
          return EstadisticasModel.fromJson(
            Map<String, dynamic>.from(fallbackData),
          );
        }
      } catch (_) {
        // Mantenemos el error original para no ocultar detalles del servidor.
      }
    }

    final detalle = e.response?.data;
    if (detalle is Map && detalle['detail'] != null) {
      throw Exception(detalle['detail'].toString());
    }
    throw Exception(
      'No se pudieron cargar tus estadisticas. Intenta de nuevo.',
    );
  }
});

final estadisticasUsuarioProvider = FutureProvider.autoDispose
    .family<EstadisticasModel, String>((ref, username) async {
      final dio = ref.read(dioProvider);

      try {
        final response = await dio.get('/estadisticas/$username');
        final data = response.data;

        if (data is Map<String, dynamic>) {
          return EstadisticasModel.fromJson(data);
        }

        if (data is Map) {
          return EstadisticasModel.fromJson(Map<String, dynamic>.from(data));
        }

        throw Exception(
          'Respuesta invalida al cargar estadisticas del usuario.',
        );
      } on DioException catch (e) {
        final detalle = e.response?.data;
        if (detalle is Map && detalle['detail'] != null) {
          throw Exception(detalle['detail'].toString());
        }
        throw Exception('No se pudieron cargar las estadisticas del usuario.');
      }
    });
