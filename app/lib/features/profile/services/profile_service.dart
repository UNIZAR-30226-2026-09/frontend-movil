import 'package:dio/dio.dart';

class ProfileService {
  final Dio dio;

  ProfileService(this.dio);

  static const String _updateProfilePath = '/usuarios/me';

  Future<void> updateProfile({
    String? email,
    String? password,
  }) async {
    final data = <String, dynamic>{};

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (password != null && password.trim().isNotEmpty) {
      data['password'] = password.trim();
    }

    if (data.isEmpty) {
      throw Exception('No hay datos para actualizar');
    }

    await dio.put(
      _updateProfilePath,
      data: data,
    );
  }

  String extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        final message = data['message'];

        if (detail is String) return detail;
        if (message is String) return message;

        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic> && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
      }

      if (data != null) return data.toString();
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return 'Ha ocurrido un error inesperado';
  }
}