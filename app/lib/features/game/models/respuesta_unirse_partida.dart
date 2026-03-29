import 'jugador_partida_model.dart';

class RespuestaUnirsePartida {
  final String mensaje;
  final List<JugadorPartidaModel> jugadoresEnSala;
  final String creador;

  RespuestaUnirsePartida({
    required this.mensaje,
    required this.jugadoresEnSala,
    required this.creador,
  });

  factory RespuestaUnirsePartida.fromJson(Map<String, dynamic> json) {
    return RespuestaUnirsePartida(
      mensaje: json['mensaje'] as String,
      creador: json['creador'] as String,
      jugadoresEnSala: (json['jugadores_en_sala'] as List<dynamic>)
          .map((e) => JugadorPartidaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}