import 'package:dio/dio.dart';

import '../models/ranking_model.dart';

class RankingService {
  RankingService(this._dio);

  final Dio _dio;

  Future<List<RankingModel>> getRanking({int limite = 10}) async {
    final response = await _dio.get(
      '/estadisticas/ranking',
      queryParameters: {
        'limite': limite,
      },
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Respuesta inesperada al obtener el ranking');
    }

    return data
        .map((item) => RankingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}