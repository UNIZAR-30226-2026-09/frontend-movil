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
    return PublicMatchModel(
      id: json['id'] as int,
      configMaxPlayers: json['config_max_players'] as int,
      configVisibility: json['config_visibility'] as String,
      codigoInvitacion: json['codigo_invitacion'] as String,
      configTimerSeconds: json['config_timer_seconds'] as int,
      estado: json['estado'] as String,
      ganador: json['ganador'] as String?,
    );
  }
}