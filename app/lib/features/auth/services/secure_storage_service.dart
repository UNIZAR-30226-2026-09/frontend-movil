import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/* Servicio encargado de guardar, leer y eliminar de forma segura los datos 
   de autenticación del usuario, como el token de acceso y el tipo de token. Utiliza la
   biblioteca flutter_secure_storage para almacenar esta información de manera segura en el dispositivo.
 */
class SecureStorageService {
  /* Instancia del almacenamiento seguro de Flutter.
     Se usa para guardar datos sensibles como el token JWT.
   */
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Claves para almacenar y recuperar el token de acceso y el tipo de token.
  static const String _tokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';


  // Guarda el token de acceso y el tipo de token en el almacenamiento seguro.
  Future<void> saveAuthToken({required String accessToken, required String tokenType}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
  }
  

  // Lee el token de acceso del almacenamiento seguro. Devuelve null si no se encuentra.
  Future<String?> readAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Lee el tipo de token del almacenamiento seguro. Devuelve null si no se encuentra.
  Future<String?> readTokenType() async {
    return await _storage.read(key: _tokenTypeKey);
  }

  // Elimina el token de acceso y el tipo de token del almacenamiento seguro, cerrando efectivamente la sesión del usuario.
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
  }
}