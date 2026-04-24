import 'estado_amistad.dart';

class AmistadModel {
  final int id;
  final String user1;
  final String user2;
  final String? username;
  final EstadoAmistad estado;

  const AmistadModel({
    required this.id,
    required this.user1,
    required this.user2,
    this.username,
    required this.estado,
  });

  factory AmistadModel.fromJson(Map<String, dynamic> json) {
    return AmistadModel(
      id: _parseId(
        json['id'] ??
            json['solicitud_id'] ??
            json['id_solicitud'],
      ),
      user1: json['user_1']?.toString() ?? '',
      user2: json['user_2']?.toString() ?? '',
      username: json['username']?.toString(),
      estado: estadoAmistadFromJson(
        json['estado']?.toString() ?? 'PENDIENTE',
      ),
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_1': user1,
      'user_2': user2,
      'username': username,
      'estado': estadoAmistadToJson(estado),
    };
  }

  String otroUsuario(String usuarioActual) {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }

    if (user1 == usuarioActual) return user2;
    if (user2 == usuarioActual) return user1;

    if (user2.isNotEmpty) return user2;
    if (user1.isNotEmpty) return user1;

    return 'Usuario desconocido';
  }

  bool enviadaPorMi(String usuarioActual) {
    return user1 == usuarioActual;
  }

  bool recibidaPorMi(String usuarioActual) {
    return user2 == usuarioActual;
  }
}