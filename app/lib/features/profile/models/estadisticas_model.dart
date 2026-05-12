class EstadisticasModel {
  final String nombreUser;
  final int numPartidasJugadas;
  final int numPartidasGanadas;
  final int numContinentesConquistados;
  final int numRegionesConquistadas;
  final int numComarcasConquistadas;
  final int numSoldadosMatados;
  final int? posicionRanking;
  final double winrate;
  final String? regionMasConquistada;
  final Map<String, dynamic> conquistasPorRegion;

  const EstadisticasModel({
    required this.nombreUser,
    required this.numPartidasJugadas,
    required this.numPartidasGanadas,
    required this.numContinentesConquistados,
    required this.numRegionesConquistadas,
    required this.numComarcasConquistadas,
    required this.numSoldadosMatados,
    required this.posicionRanking,
    required this.winrate,
    required this.regionMasConquistada,
    required this.conquistasPorRegion,
  });

  factory EstadisticasModel.fromJson(Map<String, dynamic> json) {
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

    final regionMasConquistada =
        (json['comarca_mas_conquistada'] ?? json['region_mas_conquistada'])
            ?.toString();

    return EstadisticasModel(
      nombreUser: (json['nombre_user'] ?? '').toString(),
      numPartidasJugadas: asInt(json['num_partidas_jugadas']),
      numPartidasGanadas: asInt(json['num_partidas_ganadas']),
      numContinentesConquistados: asInt(json['num_continentes_conquistados']),
      numRegionesConquistadas: asInt(json['num_regiones_conquistadas']),
      numComarcasConquistadas: asInt(json['num_comarcas_conquistadas']),
      numSoldadosMatados: asInt(json['num_soldados_matados']),
      posicionRanking: asNullableInt(json['posicion_ranking']),
      winrate: asDouble(json['winrate']),
      regionMasConquistada: regionMasConquistada?.trim().isEmpty == true
          ? null
          : regionMasConquistada,
      conquistasPorRegion: json['conquistas_por_region'] is Map
          ? Map<String, dynamic>.from(json['conquistas_por_region'] as Map)
          : const <String, dynamic>{},
    );
  }
}
