class JugadorPartidaModel {
  final String usuarioId;
  final int partidaId;
  final int turno;
  final String estadoJugador;
  final String? avatar;

  JugadorPartidaModel({
    required this.usuarioId,
    required this.partidaId,
    required this.turno,
    required this.estadoJugador,
    this.avatar,
  });

  factory JugadorPartidaModel.fromJson(Map<String, dynamic> json) {
    return JugadorPartidaModel(
      usuarioId: json['usuario_id'] as String,
      partidaId: json['partida_id'] as int,
      turno: json['turno'] as int,
      estadoJugador: json['estado_jugador'] as String,
      avatar: json['avatar']?.toString() ?? json['avatar_url']?.toString(),
    );
  }

  JugadorPartidaModel copyWith({
    String? usuarioId,
    int? partidaId,
    int? turno,
    String? estadoJugador,
    Object? avatar = _sentinel,
  }) {
    return JugadorPartidaModel(
      usuarioId: usuarioId ?? this.usuarioId,
      partidaId: partidaId ?? this.partidaId,
      turno: turno ?? this.turno,
      estadoJugador: estadoJugador ?? this.estadoJugador,
      avatar: avatar == _sentinel ? this.avatar : avatar as String?,
    );
  }
}

const Object _sentinel = Object();
