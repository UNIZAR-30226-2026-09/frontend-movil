import 'package:dio/dio.dart';
import '../../models/auth_token_response.dart';
import '../../models/user_model.dart';


// Servicio encargado de realizar las peticiones HTTP relacionadas con la autenticación del usuario.
class AuthService {

  // Instancia de Dio que usará este servicio para comunicarse con el backend.
  final Dio dio;

  AuthService(this.dio);

  /* Envía al backend los datos necesartios para registrar un nuevo usuario.
     Esta petición no devuelve el usuario logeado, solo confirma el registro.
  */
  Future<void> register ({required String username, required String password, required String email}) async {
    await dio.post('/usuarios/registro',
      data: {
        'username': username,
        'password': password,
        'email': email,
      },
    );
  }

  /* Envía las credenciales al backend para iniciar sesión.
     Devuelve el token JWT y su tipo para poder guardarlos despues en el almacenamiento seguro.
  */
  Future<AuthTokenResponse> login ({required String username, required String password}) async {
    final response = await dio.post('/usuarios/login',
      data: {
        'username': username,
        'password': password,
      },
      // El backend espera esta petición con formato form-urlencoded, por lo que se especifica el content type adecuado.
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    print('LOGIN RAW RESPONSE: ${response.data}');
    print('LOGIN RAW RESPONSE TYPE: ${response.data.runtimeType}');

    return AuthTokenResponse.fromJson(response.data);
  }

  /* Obtiene la información del usuario autenticado actualmente.
     Esta petición requiere que el token JWT se envíe correctamente en la cabecera de autorización.
  */
  Future<UserModel> getMe () async {
    final response = await dio.get('/usuarios/me');
    return UserModel.fromJson(response.data);
  }

}