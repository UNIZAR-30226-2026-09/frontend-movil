class PerfilPublicoModel {
  const PerfilPublicoModel({
    required this.nombreUser,
    required this.numPartidasJugadas,
    required this.numPartidasGanadas,
    required this.numRegionesConquistadas,
    required this.numComarcasConquistadas,
    required this.numSoldadosMatados,
    required this.posicionRanking,
    required this.avatar,
    required this.winrate,
    required this.comarcaMasConquistada,
  });

  final String nombreUser;
  final int numPartidasJugadas;
  final int numPartidasGanadas;
  final int numRegionesConquistadas;
  final int numComarcasConquistadas;
  final int numSoldadosMatados;
  final int? posicionRanking;
  final String? avatar;
  final double winrate;
  final String? comarcaMasConquistada;

  factory PerfilPublicoModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double asDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    String? asNullableString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    return PerfilPublicoModel(
      nombreUser: (json['nombre_user'] ?? '').toString(),
      numPartidasJugadas: asInt(json['num_partidas_jugadas']),
      numPartidasGanadas: asInt(json['num_partidas_ganadas']),
      numRegionesConquistadas: asInt(json['num_regiones_conquistadas']),
      numComarcasConquistadas: asInt(json['num_comarcas_conquistadas']),
      numSoldadosMatados: asInt(json['num_soldados_matados']),
      posicionRanking: asNullableInt(json['posicion_ranking']),
      avatar: asNullableString(json['avatar']),
      winrate: asDouble(json['winrate']),
      comarcaMasConquistada: asNullableString(json['comarca_mas_conquistada']),
    );
  }
}