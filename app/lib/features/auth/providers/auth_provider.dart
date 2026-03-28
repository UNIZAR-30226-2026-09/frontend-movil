import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/auth_token_response.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../../../shared/api/dio_provider.dart';

/*/* Provider que expone el servicio de almacenamiento seguro.
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
*/

/* Provider que expone el servicio de autenticación.
   Este servicio agrupa las llamadas HTTP relacionadas con login, registro y obtención del usuario autenticado.
 */
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioProvider);
  return AuthService(dio);
});


// Estados posibles del sistema de autenticación de la app.
enum AuthStatus{ 
  initial, // Estado inicial antes de comprobar si existe sesión guardada.
  loading, // Estado temporal mientras se está realizando una operación de autenticación (login, registro, check session).
  authenticated, // El usuario ha iniciado sesión correctamente.
  unauthenticated, // El usuario no tiene sesión iniciada.
}

/* Objeto que representa el estado actual de autenticación de la app.
   Guarada tanto el estado general como el usuario y posibles errores.
 */
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });


  /* Método auxiliar para crear una copia del estado actual cambiando solo algunos campos.
     Se usa Object? con _noChange para poder distinguir entr:
    - "no quiero modificar este campo" (pasando _noChange)
    - "quiero establecer este campo a null" (pasando null)
  */ 
  AuthState copyWith({
    AuthStatus? status,
    Object? user = _noChange,
    Object? errorMessage = _noChange,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user == _noChange ? this.user : user as UserModel?,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// Valor interno usado por copyWith para indicar que un campo no se debe cambiar.
const _noChange = Object();

/* Notifier encargado de gestionar toda la lógica de autenticación.
   Es el cerebro del sistema de auth dentro de la app.
*/
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final SecureStorageService secureStorage;

  AuthNotifier({
    required this.authService,
    required this.secureStorage,
  }) : super(const AuthState(status: AuthStatus.initial));


  /* Registra un nuevo usuario en el backend.
     Si el registro va bien, el usuario sigue estando no autenticado hasta que haga login.
  */
  Future<void> register ({required String username, required String password, required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try{
      await authService.register(username: username, password: password, email: email);
      state = state.copyWith(status: AuthStatus.unauthenticated, user:null, errorMessage: null);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null, errorMessage: 'Error al registrar el usuario');
    }
  }

  /* Inicia sesión contra el backend.
     Flujo:
      1. Envía credenciales.
      2. Recibe el token JWT.
      3. Guarda el token en el almacenamiento seguro.
      4. Consulta la información del usuario autenticado.
      5. Actualiza el estado a authenticated con la info del usuario.
  */
  Future<void> login ({required String username, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try{
      print('PASO 1: llamando a authService.login');
      final AuthTokenResponse tokenResponse = await authService.login(username: username, password: password);

      print('PASO 2: login correcto');
      print('TOKEN: ${tokenResponse.accessToken}');
      print('TOKEN TYPE: ${tokenResponse.tokenType}');
      await secureStorage.saveAuthToken(accessToken: tokenResponse.accessToken, tokenType: tokenResponse.tokenType);

      print('PASO 3: token guardado');
      final user = await authService.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null);
    } catch (e, st) {
      print('ERROR LOGIN FLUTTER: $e');
      print(st);
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null, errorMessage: 'Error al iniciar sesión');
    }
  }

  /* Comprueba si existe una sesión guardada al arrancar la app.
     Si hay token almacenado, intenta validar esa sesión consultando
     los datos del usuario autenticado.
     Si falla, elimina el token y deja la app como no autenticada.
  */
  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try{
      final token = await secureStorage.readAccessToken();

      if(token == null || token.isEmpty){
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null, errorMessage: null);
        return;
      }

      final user = await authService.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null);
    } catch (_) {
      await secureStorage.deleteAuthToken();

      state = state.copyWith(status: AuthStatus.unauthenticated, user: null, errorMessage: null);
    }
  }


  /* Cierra la sesión del usuario eliminando el token guardado
     y limpiando el estado de autenticación.
  */
  Future<void> logout() async {
    await secureStorage.deleteAuthToken();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null, errorMessage: null);
  }  
}


/* Provider principal de la autenticación.
   Permite a la UI leer el estado actual y ejecutar acciones como
   login, registro, check session y logout.
*/
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
    final authService = ref.read(authServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);
    return AuthNotifier(authService: authService, secureStorage: secureStorage);
  });