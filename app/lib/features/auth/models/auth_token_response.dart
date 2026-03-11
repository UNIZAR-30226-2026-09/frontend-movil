
/* Modelo que representa la respuesta del backend tras un login cofrrecto.
   Contiene el token JWT y el tipo devuelto por el backend, que se guardarán de forma segura en el dispositivo para autenticar futuras solicitudes.
 */
class AuthTokenResponse {
  // El token de acceso JWT que se usará para autenticar las solicitudes al backend.
  final String accessToken;

  // El tipo de token, generalmente "Bearer", que se usará en el encabezado de autorización.
  final String tokenType;

  AuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  /* Crea una instancia del modelo AuthTokenResponse a partir del JSON recibido del backend.
     Se usa para convertir la respuesta de login en un objeto de Dart manejable.
   */
  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}