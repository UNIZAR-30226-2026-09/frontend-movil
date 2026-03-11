import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

/* Interceptor de Dio encargado de gestionar automaticamente
   la autenticación en las peticiones HTTP. Antes de enviar una solicitud, añade el token de acceso al encabezado de autorización si está disponible.
 */
class AuthInterceptor extends Interceptor {

  // Servicio que permite acceder al token guardado de forma segura.
  final SecureStorageService secureStorage;

  AuthInterceptor(this.secureStorage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Antes de enviar una petición, se intenta leer el token guardado.
    final token = await secureStorage.readAccessToken();

    // Si existe un token válido, se añade automáticamente al encabezado de autorización de la petición pata autenticarla.
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Se deja continuar la petición.
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    /* Si el backend responde con 401, el token ya no es válido
       o la sesión ha expirado, por lo que se elimina del almacenamiento.
     */
    if (err.response?.statusCode == 401) {
      await secureStorage.deleteAuthToken();
    }

    // Se deja continuar el flujo del error.
    handler.next(err);
  }
}

  