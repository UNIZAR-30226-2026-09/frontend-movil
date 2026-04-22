class EstadisticasModel {
  final String nombreUser;
  final int numPartidasJugadas;
  final int numPartidasGanadas;
  final int numRegionesConquistadas;
  final int numSoldadosMatados;
  final Map<String, dynamic> conquistasPorRegion;

  const EstadisticasModel({
    required this.nombreUser,
    required this.numPartidasJugadas,
    required this.numPartidasGanadas,
    required this.numRegionesConquistadas,
    required this.numSoldadosMatados,
    required this.conquistasPorRegion,
  });

  factory EstadisticasModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return EstadisticasModel(
      nombreUser: (json['nombre_user'] ?? '').toString(),
      numPartidasJugadas: asInt(json['num_partidas_jugadas']),
      numPartidasGanadas: asInt(json['num_partidas_ganadas']),
      numRegionesConquistadas: asInt(json['num_regiones_conquistadas']),
      numSoldadosMatados: asInt(json['num_soldados_matados']),
      conquistasPorRegion: json['conquistas_por_region'] is Map
          ? Map<String, dynamic>.from(json['conquistas_por_region'] as Map)
          : const <String, dynamic>{},
    );
  }
}
