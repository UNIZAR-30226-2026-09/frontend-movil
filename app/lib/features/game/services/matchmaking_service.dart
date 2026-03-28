import 'package:dio/dio.dart';
import '../models/partida_publica_model.dart';

class MatchmakingService {
  final Dio dio;

  MatchmakingService(this.dio);

  Future<List<PublicMatchModel>> getPublicMatches() async {
    final response = await dio.get('/partidas');

    final data = response.data as List<dynamic>;

    return data
        .map((json) => PublicMatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinMatchByCode(String codigo) async {
    try {
      print('JOIN URL: /partidas/$codigo/unirse');
      final response = await dio.post('/partidas/$codigo/unirse');
      print('JOIN RESPONSE: ${response.data}');
      print('JOIN STATUS: ${response.statusCode}');
    } on DioException catch (e) {
      print('JOIN ERROR TYPE: ${e.type}');
      print('JOIN ERROR STATUS: ${e.response?.statusCode}');
      print('JOIN ERROR DATA: ${e.response?.data}');
      rethrow;
    }
  }
}