class PublicMatchModel {
  final int id;
  final int configMaxPlayers;
  final String configVisibility;
  final String codigoInvitacion;
  final int configTimerSeconds;
  final String estado;
  final String? ganador;

  PublicMatchModel({
    required this.id,
    required this.configMaxPlayers,
    required this.configVisibility,
    required this.codigoInvitacion,
    required this.configTimerSeconds,
    required this.estado,
    required this.ganador,
  });

  factory PublicMatchModel.fromJson(Map<String, dynamic> json) {
    final id =
        json['id'] as int? ??
        json['partida_id'] as int? ??
        json['id_partida'] as int? ??
        0;

    final configMaxPlayers = json['config_max_players'] as int? ?? 0;
    final configVisibility = json['config_visibility'] as String? ?? '';
    final codigoInvitacion =
        json['codigo_invitacion'] as String? ??
        json['codigo'] as String? ??
        '';
    final rawTimer = json['config_timer_seconds'];
    final configTimerSeconds = rawTimer is int
        ? rawTimer
        : (rawTimer is num
            ? rawTimer.toInt()
            : int.tryParse(rawTimer?.toString() ?? '') ?? 0);

    final estado = (json['estado'] as String? ?? '').toUpperCase();

    final ganador = json['ganador'] as String?;

    return PublicMatchModel(
      id: id,
      configMaxPlayers: configMaxPlayers,
      configVisibility: configVisibility,
      codigoInvitacion: codigoInvitacion,
      configTimerSeconds: configTimerSeconds,
      estado: estado,
      ganador: ganador,
    );
  }
}