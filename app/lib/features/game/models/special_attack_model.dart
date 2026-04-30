import 'package:flutter/material.dart';

import 'tech_tree_model.dart';

enum SpecialAttackTargetType { territory, player }

enum SpecialAttackTargetSide { enemy, ally, any, self }

class SpecialAttackModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String endpoint;
  final String method;
  final int? minRange;
  final int? maxRange;
  final SpecialAttackTargetType targetType;
  final SpecialAttackTargetSide targetSide;
  final bool requiresOrigin;
  final bool requiresTarget;
  final Map<String, String> payloadMapping;
  final Map<String, dynamic> metadata;

  const SpecialAttackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.endpoint,
    required this.method,
    required this.targetType,
    required this.targetSide,
    required this.requiresOrigin,
    required this.requiresTarget,
    required this.payloadMapping,
    required this.metadata,
    this.minRange,
    this.maxRange,
  });

  static SpecialAttackModel? fromTechNode(TechNodeModel node) {
    final rawConfig = _extractConfig(node.metadata) ?? _inferConfig(node);
    if (rawConfig == null) return null;

    final config = <String, dynamic>{...node.metadata, ...rawConfig};
    final endpoint =
        _stringFromKeys(config, const <String>[
          'endpoint',
          'ruta',
          'path',
        ]) ??
        '/partidas/{partidaId}/ataque_especial';

    final targetType = _parseTargetType(
      _stringFromKeys(config, const <String>[
        'target_type',
        'tipo_objetivo',
        'objetivo_tipo',
      ]),
    );
    final targetSide = _parseTargetSide(
      _stringFromKeys(config, const <String>[
        'target_side',
        'objetivo_bando',
        'ownership',
      ]),
    );

    final exactRange = _intFromKeys(config, const <String>[
      'exact_range',
      'alcance_exacto',
    ]);
    final minRange = exactRange ?? _intFromKeys(config, const <String>[
      'min_range',
      'alcance_min',
      'alcance_minimo',
    ]);
    final range = exactRange ?? _intFromKeys(config, const <String>[
      'max_range',
      'range',
      'alcance',
      'alcance_max',
      'alcance_maximo',
    ]);

    return SpecialAttackModel(
      id: node.id,
      name: node.name,
      description: node.description,
      icon: node.icon,
      endpoint: endpoint,
      method: (_stringFromKeys(config, const <String>[
            'method',
            'metodo',
          ]) ??
          'POST')
          .toUpperCase(),
      minRange: minRange,
      maxRange: range,
      targetType: targetType,
      targetSide: targetSide,
      requiresOrigin:
          _boolFromKeys(config, const <String>[
            'requires_origin',
            'requiere_origen',
          ]) ??
          targetType == SpecialAttackTargetType.territory,
      requiresTarget:
          _boolFromKeys(config, const <String>[
            'requires_target',
            'requiere_objetivo',
          ]) ??
          true,
      payloadMapping: _parsePayloadMapping(config),
      metadata: config,
    );
  }

  String get endpointPath =>
      endpoint.contains('{partidaId}') ? endpoint : endpoint.trim();

  String targetFieldName() {
    if (payloadMapping.containsKey('target')) {
      return payloadMapping['target']!;
    }
    return 'destino';
  }

  static Map<String, dynamic>? _extractConfig(Map<String, dynamic> metadata) {
    final nested = metadata['ataque_especial'] ??
        metadata['special_attack'] ??
        metadata['accion_especial'] ??
        metadata['combat_action'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    if (nested == true) {
      return metadata;
    }

    final type = _stringFromKeys(metadata, const <String>[
      'tipo_accion',
      'action_type',
      'tipo',
    ]);
    if (type == 'ataque_especial' || type == 'special_attack') {
      return metadata;
    }

    return null;
  }

  static Map<String, dynamic>? _inferConfig(TechNodeModel node) {
    final id = node.id.trim().toLowerCase();
    final inferred = _inferredSpecialAttacks[id];
    if (inferred == null) return null;

    final range = _intFromKeys(node.metadata, const <String>[
      'rango',
      'range',
      'alcance',
    ]);

    return <String, dynamic>{
      'endpoint': '/partidas/{partidaId}/ataque_especial',
      'method': 'POST',
      'payload_mapping': const <String, String>{
        'attack': 'tipo_ataque',
        'origin': 'origen',
        'target': 'destino',
      },
      ...?range == null ? null : <String, dynamic>{'range': range},
      ...inferred,
    };
  }

  static const Map<String, Map<String, dynamic>> _inferredSpecialAttacks =
      <String, Map<String, dynamic>>{
        'gripe_aviar': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'vacuna_universal': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'self',
          'requires_origin': false,
        },
        'fatiga': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'coronavirus': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'inhibidor_senal': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'propaganda_subversiva': <String, dynamic>{
          'target_type': 'player',
          'target_side': 'enemy',
          'requires_origin': false,
        },
        'muro_fronterizo': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'sanciones_internacionales': <String, dynamic>{
          'target_type': 'player',
          'target_side': 'enemy',
          'requires_origin': false,
        },
        'mortero_tactico': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'misil_crucero': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'cabeza_nuclear': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
        'bomba_racimo': <String, dynamic>{
          'target_type': 'territory',
          'target_side': 'enemy',
        },
      };

  static Map<String, String> _parsePayloadMapping(Map<String, dynamic> config) {
    final raw = config['payload_mapping'] ?? config['payload'] ?? config['body'];
    if (raw is! Map) {
      return const <String, String>{};
    }

    final output = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value?.toString().trim() ?? '';
      if (key.isEmpty || value.isEmpty) continue;
      output[key] = value;
    }
    return output;
  }

  static String? _stringFromKeys(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _intFromKeys(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool? _boolFromKeys(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is bool) return value;
      if (value is num) return value != 0;

      final text = value?.toString().trim().toLowerCase() ?? '';
      if (text == 'true' || text == '1' || text == 'si' || text == 'yes') {
        return true;
      }
      if (text == 'false' || text == '0' || text == 'no') {
        return false;
      }
    }
    return null;
  }

  static SpecialAttackTargetType _parseTargetType(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    if (normalized.contains('player') || normalized.contains('jugador')) {
      return SpecialAttackTargetType.player;
    }
    return SpecialAttackTargetType.territory;
  }

  static SpecialAttackTargetSide _parseTargetSide(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    if (normalized.contains('self') || normalized.contains('propio')) {
      return SpecialAttackTargetSide.self;
    }
    if (normalized.contains('ally') || normalized.contains('aliad')) {
      return SpecialAttackTargetSide.ally;
    }
    if (normalized.contains('any') || normalized.contains('cualquiera')) {
      return SpecialAttackTargetSide.any;
    }
    return SpecialAttackTargetSide.enemy;
  }
}
