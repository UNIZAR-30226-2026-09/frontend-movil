import 'package:dio/dio.dart';
import '../models/amistad_model.dart';
import '../models/estado_amistad.dart';

class AmigosService {
  final Dio dio;

  AmigosService(this.dio);

  Future<List<AmistadModel>> listarAmigos() async {
    final response = await dio.get('/amigos');

    final data = response.data as List<dynamic>;

    return data
        .map((json) => AmistadModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AmistadModel> solicitarAmistad(String user2) async {
    final response = await dio.post(
      '/amigos/solicitar',
      data: {
        'user_2': user2,
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  

    return AmistadModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AmistadModel>> listarSolicitudes() async {
    final response = await dio.get('/amigos/solicitudes');

    final data = response.data as List<dynamic>;

    return data
        .map((json) => AmistadModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AmistadModel> procesarSolicitud({
    required int solicitudId,
    required EstadoAmistad estado,
  }) async {
    final response = await dio.put(
      '/amigos/solicitudes/$solicitudId',
      data: {
        'estado': estadoAmistadToJson(estado),
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );

    return AmistadModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminarAmigo(int amigoId) async {
    await dio.delete('/amigos/$amigoId');
  }
}