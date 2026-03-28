import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/services/secure_storage_service.dart';
import '../api/dio_client.dart';


/* Provider que expone el servicio de almacenamiento seguro.
   Se usa para guardar, leer y eliminar el token JWT.
 */
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});


/* Provider que expone la instancia de Dio ya ocnfigurada.
   Esta instancia incluye la URL base y el interceptor de autenticación.
 */
final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return DioClient(secureStorage).dio;
});