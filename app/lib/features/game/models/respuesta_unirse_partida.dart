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
    final rawAvatares = json['avatares'];
    final avataresPorUsuario = <String, String>{};
    if (rawAvatares is Map) {
      rawAvatares.forEach((key, value) {
        final username = key.toString().trim();
        final avatar = value?.toString().trim() ?? '';
        if (username.isNotEmpty && avatar.isNotEmpty) {
          avataresPorUsuario[username] = avatar;
        }
      });
    }

    return RespuestaUnirsePartida(
      mensaje: json['mensaje'] as String,
      creador: json['creador'] as String,
      jugadoresEnSala: (json['jugadores_en_sala'] as List<dynamic>)
          .map((e) {
            final jugador = JugadorPartidaModel.fromJson(
              e as Map<String, dynamic>,
            );
            return jugador.copyWith(
              avatar: avataresPorUsuario[jugador.usuarioId] ?? jugador.avatar,
            );
          })
          .toList(),
    );
  }
}
