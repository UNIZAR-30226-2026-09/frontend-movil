import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/territory_model.dart';

class GameMap {
  final List<Region> regions;
  final List<Comarca> comarcas;

  GameMap({required this.regions, required this.comarcas});
}

class MapLoader {
  static Future<GameMap> loadMap() async {
    final String response = await rootBundle.loadString('assets/json/map_aragon.json');
    final data = await json.decode(response);
    
    List<Region> regions = [];
    List<Comarca> comarcas = [];
    
    // Cargamos las regiones (Frontera Pirenaica, Alto Ebro, etc.)
    data['regions'].forEach((key, value) {
      regions.add(Region.fromJson(key, value));
    });

    // Cargamos las comarcas (Jacetania, Monegros, etc.)
    data['comarcas'].forEach((key, value) {
      comarcas.add(Comarca.fromJson(key, value));
    });
    
    return GameMap(regions: regions, comarcas: comarcas);
  }
}