import 'package:dio/dio.dart';
import '../models/partida_publica_model.dart';
import '../models/respuesta_unirse_partida.dart';

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

  // Devuelve la partida activa o pausada del usuario, o null si no tiene ninguna.
  // Devuelve la partida activa o pausada del usuario, o null si no tiene ninguna.
  Future<List<PublicMatchModel>> getPartidasPausadas() async {
    final response = await dio.get('/partidas/pausadas');
    return (response.data as List)
        .map((j) => PublicMatchModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<PublicMatchModel?> getMiPartidaActiva() async {
    try {
      final response = await dio.get('/partidas/mi-partida');
      if (response.data == null) return null;
      
      // CHIVATOS PARA LA CONSOLA
      print('🟢 JSON RECIBIDO DE MI-PARTIDA: ${response.data}');
      
      return PublicMatchModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      print('🔴 DIO ERROR MI PARTIDA: ${e.response?.data}');
      rethrow;
    } catch (e, stack) {
      // AQUÍ CAZAMOS EL ERROR DE PARSEO
      print('💥 ERROR DE PARSEO EN MI PARTIDA: $e');
      print(stack);
      rethrow;
    }
  }

  // Devuelve el estado detallado de una partida concreta.
  Future<Map<String, dynamic>> getEstadoPartida(int partidaId) async {
    final response = await dio.get('/partidas/$partidaId/estado');
    return response.data as Map<String, dynamic>;
  }

  Future<RespuestaUnirsePartida> joinMatchByCode(String codigo) async {
    try {
      final response = await dio.post('/partidas/$codigo/unirse');
      return RespuestaUnirsePartida.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print('JOIN ERROR TYPE: ${e.type}');
      print('JOIN ERROR STATUS: ${e.response?.statusCode}');
      print('JOIN ERROR DATA: ${e.response?.data}');
      rethrow;
    }
  }

  Future<PublicMatchModel> createMatch({
    required int maxPlayers,
    required String visibility,
    required int timerSeconds,
  }) async {
    print('CREATE MATCH HEADERS: ${dio.options.headers}');
    final response = await dio.post(
      '/partidas',
      data: {
        'config_max_players': maxPlayers,
        'config_visibility': visibility,
        'config_timer_seconds': timerSeconds,
      },
    );
    print('CREATE MATCH RESPONSE: ${response.data}');
    return PublicMatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leaveMatch(int partidaId) async {
    await dio.post('/partidas/$partidaId/abandonar');
  }

  // El host reanuda una partida que estaba pausada.
  Future<void> reanudarPartida(String code) async {
    await dio.post('/partidas/$code/reanudar');
  }

  // Solicita iniciar una votación de pausa. Solo tiene efecto durante una partida activa.
  Future<void> solicitarPausa(String code) async {
    await dio.post('/partidas/$code/pausa/solicitar');
  }

  // Emite el voto del jugador sobre la pausa en curso.
  Future<void> votarPausa(String code, {required bool aFavor}) async {
    await dio.post(
      '/partidas/$code/pausa/votar',
      data: {'voto_a_favor': aFavor},
    );
  }
}
