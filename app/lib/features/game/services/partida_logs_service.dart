import 'package:dio/dio.dart';

import '../models/partida_log_model.dart';

class PartidaLogsService {
  final Dio dio;

  const PartidaLogsService(this.dio);

  Future<List<PartidaLogModel>> fetchLogs({
    required int partidaId,
    int limit = 50,
  }) async {
    final response = await dio.get(
      '/partidas/$partidaId/logs',
      queryParameters: {'limit': limit},
    );

    final data = response.data;
    if (data is! List) return const <PartidaLogModel>[];

    return data
        .whereType<Map>()
        .map((raw) => PartidaLogModel.fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
  }
}
