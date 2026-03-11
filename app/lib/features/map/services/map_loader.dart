import 'dart:convert';
import 'dart:ui' show Path;
import 'package:flutter/services.dart';
import '../models/territory_model.dart';
import '../config/map_data.dart';
import 'package:path_drawing/path_drawing.dart';

class GameMap {
  final List<Region> regions;
  final List<Comarca> comarcas;

  final Map<String, Path> comarcaPaths;

  GameMap({
    required this.regions, 
    required this.comarcas, 
    required this.comarcaPaths
  });
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

    final Map<String, Path> comarcaPaths = {};
    for (final entry in MapPaths.data.entries) {
      comarcaPaths[entry.key] = parseSvgPathData(entry.value);
    }
    
    return GameMap(regions: regions, comarcas: comarcas, comarcaPaths: comarcaPaths);
  }
}