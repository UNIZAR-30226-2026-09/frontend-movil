import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/dio_provider.dart';
import '../models/perfil_publico_model.dart';

final perfilPublicoProvider =
    FutureProvider.autoDispose.family<PerfilPublicoModel, String>(
  (ref, username) async {
    final dio = ref.read(dioProvider);

    try {
      final response = await dio.get('/estadisticas/$username');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return PerfilPublicoModel.fromJson(data);
      }

      if (data is Map) {
        return PerfilPublicoModel.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception('Respuesta inválida al cargar el perfil del usuario.');
    } on DioException catch (e) {
      final detalle = e.response?.data;

      if (detalle is Map && detalle['detail'] != null) {
        throw Exception(detalle['detail'].toString());
      }

      throw Exception('No se pudo cargar el perfil del usuario.');
    }
  },
);