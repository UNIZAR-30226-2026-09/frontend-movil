import 'package:flutter/material.dart';

enum TechBranch { biologica, operaciones, artilleria }

class TechNodeModel {
  final String id;
  final String name;
  final String description;
  final int tier;
  final int cost;
  final TechBranch branch;
  final IconData icon;
  final Offset position;
  final List<String> prerequisites;
  final Map<String, dynamic> metadata;

  const TechNodeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.cost,
    required this.branch,
    required this.icon,
    required this.position,
    this.prerequisites = const <String>[],
    this.metadata = const <String, dynamic>{},
  });
}
