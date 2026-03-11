// Clase que contiene la configuración de la API, en este caso la URL base.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // URL base de la API del backend.
  static String get baseUrl => dotenv.env['API_BASE_URL']!;
}