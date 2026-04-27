class PartidaLogModel {
  final int id;
  final int partidaId;
  final int turnoNumero;
  final String fase;
  final DateTime? timestamp;
  final String tipoEvento;
  final String? user;
  final Map<String, dynamic> datos;

  const PartidaLogModel({
    required this.id,
    required this.partidaId,
    required this.turnoNumero,
    required this.fase,
    required this.timestamp,
    required this.tipoEvento,
    required this.user,
    required this.datos,
  });

  factory PartidaLogModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is String && rawTimestamp.trim().isNotEmpty) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp);
    }

    return PartidaLogModel(
      id: _parseInt(json['id']),
      partidaId: _parseInt(json['partida_id']),
      turnoNumero: _parseInt(json['turno_numero']),
      fase: json['fase']?.toString() ?? '',
      timestamp: parsedTimestamp,
      tipoEvento: json['tipo_evento']?.toString() ?? 'SIN_TIPO',
      user: json['user']?.toString(),
      datos: json['datos'] is Map
          ? Map<String, dynamic>.from(json['datos'] as Map)
          : const <String, dynamic>{},
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
