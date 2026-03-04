import 'package:flutter/material.dart';

class ColorUtils {
  /// Colores de las regiones (Identidad visual del mapa)
  static Color getColorRegion(String regionId) {
    switch (regionId) {
      case 'frontera_pirenaica': return const Color(0xFF4ADE80);
      case 'estepas_y_condados': return const Color(0xFFFACC15);
      case 'alto_ebro':          return const Color(0xFF60A5FA);
      case 'campos_serrania':    return const Color(0xFFC084FC);
      case 'valles_matarrana':   return const Color(0xFFF87171);
      case 'sierras_sur':        return const Color(0xFFFB923C);
      default:                   return const Color(0xFFCBD5E1);
    }
  }

  /// Colores de estado 
  static const Color origenColor = Color(0xFF3B82F6);    // Azul (Seleccionada)
  static const Color resaltadoColor = Color(0xFFEAB308); // Dorado (Atacables)
  static const Color bordeColor = Colors.white;
}