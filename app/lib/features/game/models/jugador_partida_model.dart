class JugadorPartidaModel {
  final String usuarioId;
  final int partidaId;
  final int turno;
  final String estadoJugador;

  JugadorPartidaModel({
    required this.usuarioId,
    required this.partidaId,
    required this.turno,
    required this.estadoJugador,
  });

  factory JugadorPartidaModel.fromJson(Map<String, dynamic> json) {
    return JugadorPartidaModel(
      usuarioId: json['usuario_id'] as String,
      partidaId: json['partida_id'] as int,
      turno: json['turno'] as int,
      estadoJugador: json['estado_jugador'] as String,
    );
  }
}