/* Modelo que representa a un usuario de la aplicación.
   Se usa para almacenar la información básica devuelta por el backend sobre el usuario autenticado, 
   como su nombre de usuario y correo electrónico.
 */
class UserModel {
  // Nombre de usuario único del jugador.
  final String username;

  // Correo electrónico asociado a la cuenta del jugador.
  final String email;

  UserModel({
    required this.username,
    required this.email,
  });

  /* Crea una instancia del usuario a partir del JSON recibido del backend.
     Se usará al consultar información del usuario autenticado para convertir la respuesta en un objeto manejable en Dart.
   */
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}