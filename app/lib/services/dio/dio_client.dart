import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../auth/auth_interceptor.dart';
import '../auth/secure_storage_service.dart';


/* Cliente HTTP centralizado de la aplicación que utiliza Dio para realizar las solicitudes al backend.
   Se encarga de crear y configurar la instancia de Dio que usará el proyecto para comunicarse con el backend.
 */
class DioClient {

  // Servicio de almacenamiento sefuro necesario para que el interceptor pueda leer el token JWT guardado.
  final SecureStorageService secureStorage;

  // Instancia principal de Dio ya configurada.
  late final Dio dio;

  DioClient(this.secureStorage) {
    dio = Dio(
      BaseOptions(

        // URL base de la API del backend. Se concatena automáticamente con las rutas que se usen en las peticiones.
        baseUrl: ApiConfig.baseUrl,

        // Tiempo máximo para establecer conexión con el servidor.
        connectTimeout: const Duration(seconds: 10),

        // Tiempo máximo de espera para recibir respuesta del servidor.
        receiveTimeout: const Duration(seconds: 10),

        // Headers por defecto para las peticiones JSON.
        headers: {
          'Content-Type': 'application/json',
        },
      )
    );

    /* Se añade el interceptor de autenticación para que el token se 
       inyecte automáticamente en las peticiones protegidas.
    */
    dio.interceptors.add(AuthInterceptor(secureStorage));
  }
}