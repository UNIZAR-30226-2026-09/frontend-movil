import 'package:flutter/material.dart';

class MapColors {
  static Color hex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = int.parse(cleaned, radix: 16);
    if (cleaned.length == 6) {
      return Color(0xFF000000 | value);
    }
    // Por si alguna vez viene ARGB
    if (cleaned.length == 8) {
      return Color(value);
    }
    throw FormatException('Invalid hex color: $hex');
  }

  /// Colores por ID "canonical" (los IDs que tú usas en MapPaths.data / JSON)
  static final Map<String, Color> comarcaFill = {
    // EJEMPLOS (rellena con todos los del SVG web):
    'jacetania': hex('#4db29a'), // en web: la_jacetania
    'alto_gallego': hex('#0049f7'),
    'sobrarbe': hex('#8cca82'),
    'ribagorza': hex('#4d53b2'), // en web: la_ribagorza
    'hoya_de_huesca': hex('#4d53b2'),
    'somontano_de_barbastro': hex('#ac4db2'),
    'la_litera': hex('#4da4b2'), // en web: litera
    'cinca_medio': hex('#dde01f'),
    'bajo_cinca': hex('#4cf8f8'),
    'monegros': hex('#66f84c'), // en web: los_monegros
    'cinco_villas': hex('#9e6d01'),
    'ribera_alta_del_ebro': hex('#01119e'), // en web: ribera_alta_ebro
    'campo_de_borja': hex('#9e0189'), // en web: campo_de_boja (typo)
    'tarazona_y_el_moncayo': hex('#01929e'),
    'comarca_central': hex('#01929e'), // en web: zaragoza
    'valdejalon': hex('#9e0101'), // en web: villa_de_jalon
    'aranda': hex('#4cfe74'),
    'comunidad_de_calatayud': hex('#4cebfe'),
    'campo_de_carinena': hex('#844cfe'),
    'campo_de_daroca': hex('#fe4cf3'),
    'campo_de_belchite': hex('#fef14c'),
    'ribera_baja_del_ebro': hex('#f9fe06'),
    'bajo_aragon_caspe': hex('#fe0606'),
    'bajo_aragon': hex('#19fe06'),
    'bajo_martin': hex('#2006fe'),
    'andorra_sierra_de_arcos': hex('#ce06fe'), // en web: andorra
    'cuencas_mineras': hex('#fe0624'),
    'jiloca': hex('#7187fe'),
    'sierra_de_albarracin': hex('#71fe73'),
    'comunidad_de_teruel': hex('#2701a0'), // en web: comunidad_teruel
    'gudar_javalambre': hex('#06a001'), // en web: gudar
    'maestrazgo': hex('#b5e8ff'),
    'matarrana': hex('#06f7fe'),
  };

  /// Si quieres un fallback claro
  static const Color fallbackFill = Color(0x5532C7FF); // cyan translúcido
}