import 'package:flutter/material.dart';

class Region {
  final String id;
  final String name;
  final int bonusTroops;
  final List<String> comarcasIds;

  Region({
    required this.id,
    required this.name,
    required this.bonusTroops,
    required this.comarcasIds,
  });

  factory Region.fromJson(String id, Map<String, dynamic> json) {
    return Region(
      id: id,
      name: json['name'],
      bonusTroops: json['bonus_troops'],
      comarcasIds: List<String>.from(json['comarcas']),
    );
  }
}

class Comarca {
  final String id;
  final String name;
  final String regionId;
  final List<String> adjacentTo;

  Comarca({
    required this.id,
    required this.name,
    required this.regionId,
    required this.adjacentTo,
  });

  // Función para convertir el JSON en un objeto de Dart
  factory Comarca.fromJson(String id, Map<String, dynamic> json) {
    return Comarca(
      id: id,
      name: json['name'],
      regionId: json['region_id'],
      adjacentTo: List<String>.from(json['adjacent_to']),
    );
  }
}