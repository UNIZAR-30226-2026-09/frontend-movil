class RankingModel {
  const RankingModel({
    required this.nombreUser,
    required this.numPartidasGanadas,
    required this.numPartidasJugadas,
    required this.numSoldadosMatados,
    required this.avatar,
    required this.winrate,
  });

  final String nombreUser;
  final int numPartidasGanadas;
  final int numPartidasJugadas;
  final int numSoldadosMatados;
  final String? avatar;
  final double winrate;

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      nombreUser: json['nombre_user'] as String? ?? 'Jugador',
      numPartidasGanadas: json['num_partidas_ganadas'] as int? ?? 0,
      numPartidasJugadas: json['num_partidas_jugadas'] as int? ?? 0,
      numSoldadosMatados: json['num_soldados_matados'] as int? ?? 0,
      avatar: json['avatar'] as String?,
      winrate: (json['winrate'] as num?)?.toDouble() ?? 0,
    );
  }
}