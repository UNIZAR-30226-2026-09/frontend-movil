import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/tech_tree_model.dart';

class TechCatalogViewData {
  final List<TechNodeModel> nodes;
  final Size canvasSize;
  final Set<String> unlockedTechIds;
  final Set<String> ownedTechIds;
  final bool hasAuthoritativeAvailability;

  const TechCatalogViewData({
    required this.nodes,
    required this.canvasSize,
    this.unlockedTechIds = const <String>{},
    this.ownedTechIds = const <String>{},
    this.hasAuthoritativeAvailability = false,
  });

  const TechCatalogViewData.empty()
    : nodes = const <TechNodeModel>[],
      canvasSize = const Size(1200, 790),
      unlockedTechIds = const <String>{},
      ownedTechIds = const <String>{},
      hasAuthoritativeAvailability = false;
}

class TechCatalogService {
  final Dio dio;

  const TechCatalogService(this.dio);

  Future<TechCatalogViewData> fetchCatalog({required int partidaId}) async {
    final response = await dio.get('/partidas/$partidaId/tecnologias');
    final payload = _extractCatalogPayload(response.data);
    if (payload == null) {
      if (response.data is Map) {
        final keys = (response.data as Map).keys.join(', ');
        debugPrint('Payload de tecnologias no reconocido. Keys: $keys');
      }
      return const TechCatalogViewData.empty();
    }

    final prices = _parsePrices(payload['precios']);
    return _parseTree(payload['arbol'], prices);
  }

  Future<void> buyTechnology({
    required int partidaId,
    required String technologyId,
  }) async {
    await dio.post(
      '/partidas/$partidaId/comprar_tecnologia',
      data: {'tecnologia_id': technologyId},
    );
  }

  Map<String, dynamic>? _extractCatalogPayload(dynamic raw) {
    if (raw is! Map) return null;

    final root = Map<String, dynamic>.from(raw);
    if (root.containsKey('arbol') || root.containsKey('precios')) {
      return root;
    }

    final ramas = root['ramas'];
    if (ramas is Map) {
      return <String, dynamic>{
        'arbol': Map<String, dynamic>.from(ramas),
        'precios': root['precios'],
      };
    }

    final data = root['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      if (nested.containsKey('arbol') || nested.containsKey('precios')) {
        return nested;
      }

      final nestedRamas = nested['ramas'];
      if (nestedRamas is Map) {
        return <String, dynamic>{
          'arbol': Map<String, dynamic>.from(nestedRamas),
          'precios': nested['precios'] ?? root['precios'],
        };
      }
    }

    final technologies = root['tecnologias'];
    if (technologies is Map) {
      return <String, dynamic>{
        'arbol': Map<String, dynamic>.from(technologies),
        'precios': root['precios'],
      };
    }

    return null;
  }

  Map<String, int> _parsePrices(dynamic raw) {
    if (raw is! Map) return const <String, int>{};

    final output = <String, int>{};
    for (final entry in raw.entries) {
      final id = _normalizeTechId(entry.key.toString());
      if (id.isEmpty) continue;
      final cost = _toInt(entry.value);
      if (cost != null) {
        output[id] = cost;
      }
    }

    return output;
  }

  TechCatalogViewData _parseTree(dynamic raw, Map<String, int> prices) {
    if (raw == null) return const TechCatalogViewData.empty();

    final drafts = <_TechNodeDraft>[];

    if (raw is List) {
      drafts.addAll(
        _parseNodeList(raw, defaultBranchId: 'operaciones', defaultTier: 1),
      );
    } else if (raw is Map) {
      final treeMap = Map<String, dynamic>.from(raw);

      if (_looksLikeTopLevelNodeMap(treeMap)) {
        final list = treeMap.entries
            .map((entry) {
              final map = entry.value is Map
                  ? (Map<String, dynamic>.from(entry.value as Map)
                      ..putIfAbsent('id', () => entry.key.toString()))
                  : <String, dynamic>{'id': entry.key.toString()};
              return map;
            })
            .toList(growable: false);

        drafts.addAll(
          _parseNodeList(list, defaultBranchId: 'operaciones', defaultTier: 1),
        );
      } else {
        for (final branchEntry in treeMap.entries) {
          final branchId = _normalizeTechId(branchEntry.key.toString());
          if (branchId.isEmpty) continue;

          final branchValue = branchEntry.value;
          if (branchValue is List) {
            drafts.addAll(
              _parseNodeList(
                branchValue,
                defaultBranchId: branchId,
                defaultTier: 1,
              ),
            );
            continue;
          }

          if (branchValue is! Map) continue;
          final levelsMap = Map<String, dynamic>.from(branchValue);

          final tierKeys = levelsMap.keys
              .map((key) => _toInt(key))
              .whereType<int>()
              .toList(growable: false);

          if (tierKeys.isNotEmpty) {
            final tiers = levelsMap.entries.toList()
              ..sort((a, b) {
                final ai = _toInt(a.key) ?? 0;
                final bi = _toInt(b.key) ?? 0;
                return ai.compareTo(bi);
              });

            final idsByTier = <int, List<String>>{};
            for (final tierEntry in tiers) {
              final tier = _toInt(tierEntry.key) ?? 1;
              final parsedTier = _parseNodeList(
                tierEntry.value is List
                    ? tierEntry.value as List
                    : <dynamic>[tierEntry.value],
                defaultBranchId: branchId,
                defaultTier: tier,
              );

              final fallbackPrereqs = List<String>.from(
                idsByTier[tier - 1] ?? const <String>[],
              );
              final normalizedTier = parsedTier
                  .map((node) {
                    if (node.prerequisites.isNotEmpty || tier <= 1) return node;
                    return node.copyWith(prerequisites: fallbackPrereqs);
                  })
                  .toList(growable: false);

              idsByTier[tier] = normalizedTier
                  .map((node) => node.id)
                  .toList(growable: false);
              drafts.addAll(normalizedTier);
            }
            continue;
          }

          final nestedNodes = levelsMap.entries
              .map((entry) {
                if (entry.value is Map) {
                  return Map<String, dynamic>.from(entry.value as Map)
                    ..putIfAbsent('id', () => entry.key.toString());
                }
                return <String, dynamic>{'id': entry.key.toString()};
              })
              .toList(growable: false);

          drafts.addAll(
            _parseNodeList(
              nestedNodes,
              defaultBranchId: branchId,
              defaultTier: 1,
            ),
          );
        }
      }
    }

    final nodes = _buildVisualNodes(drafts, prices);
    if (nodes.isEmpty) return const TechCatalogViewData.empty();

    final unlockedTechIds = drafts
        .where((draft) => draft.preUnlocked == true)
        .map((draft) => draft.id)
        .toSet();
    final ownedTechIds = drafts
        .where((draft) => draft.owned == true)
        .map((draft) => draft.id)
        .toSet();
    final hasAuthoritativeAvailability = drafts.any(
      (draft) => draft.preUnlocked != null || draft.owned != null,
    );

    final branchIds = nodes.map((node) => node.branch).toSet().length;
    final maxTier = nodes
        .map((node) => node.tier)
        .fold<int>(1, (a, b) => a > b ? a : b);

    const startX = 120.0;
    const branchSpacing = 400.0;
    const startY = 190.0;
    const tierSpacing = 230.0;

    final width = (startX + ((branchIds - 1) * branchSpacing) + 300)
        .clamp(1100, 2400)
        .toDouble();
    final height = (startY + ((maxTier - 1) * tierSpacing) + 250)
        .clamp(760, 1800)
        .toDouble();

    return TechCatalogViewData(
      nodes: nodes,
      canvasSize: Size(width, height),
      unlockedTechIds: unlockedTechIds,
      ownedTechIds: ownedTechIds,
      hasAuthoritativeAvailability: hasAuthoritativeAvailability,
    );
  }

  bool _looksLikeTopLevelNodeMap(Map<String, dynamic> raw) {
    if (raw.isEmpty) return false;

    var hints = 0;
    for (final value in raw.values) {
      if (value is! Map) continue;
      final map = Map<String, dynamic>.from(value);
      if (map.containsKey('rama') ||
          map.containsKey('branch') ||
          map.containsKey('tier') ||
          map.containsKey('nivel') ||
          map.containsKey('prerequisito') ||
          map.containsKey('requisitos') ||
          map.containsKey('prerequisitos')) {
        hints++;
      }
    }

    return hints > 0;
  }

  List<_TechNodeDraft> _parseNodeList(
    List<dynamic> rawNodes, {
    required String defaultBranchId,
    required int defaultTier,
  }) {
    final output = <_TechNodeDraft>[];

    for (final item in rawNodes) {
      if (item == null) continue;

      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final id = _normalizeTechId(
          (map['id'] ?? map['tecnologia_id'] ?? map['clave'] ?? map['key'])
                  ?.toString() ??
              '',
        );
        if (id.isEmpty) continue;

        final branchId = _normalizeTechId(
          (map['rama'] ?? map['branch'] ?? map['familia'])?.toString() ??
              defaultBranchId,
        );
        final tier =
            _toInt(map['tier'] ?? map['nivel'] ?? map['level']) ?? defaultTier;

        output.add(
          _TechNodeDraft(
            id: id,
            branchId: branchId.isEmpty ? defaultBranchId : branchId,
            tier: tier,
            name: (map['nombre'] ?? map['name'] ?? map['titulo'])?.toString(),
            description:
                (map['descripcion'] ?? map['description'] ?? map['detalle'])
                    ?.toString(),
            cost: _toInt(
              map['coste'] ?? map['costo'] ?? map['cost'] ?? map['precio'],
            ),
            prerequisites: _parsePrerequisites(map),
            preUnlocked: _toBool(
              map['predesbloqueada'] ?? map['preunlocked'] ?? map['unlocked'],
            ),
            owned: _toBool(
              map['comprada'] ?? map['owned'] ?? map['investigada'],
            ),
          ),
        );
        continue;
      }

      final id = _normalizeTechId(item.toString());
      if (id.isEmpty) continue;

      output.add(
        _TechNodeDraft(
          id: id,
          branchId: defaultBranchId,
          tier: defaultTier,
          name: null,
          description: null,
          cost: null,
          prerequisites: const <String>[],
          preUnlocked: null,
          owned: null,
        ),
      );
    }

    return output;
  }

  List<String> _parsePrerequisites(Map<String, dynamic> map) {
    final raw =
        map['requisitos'] ??
        map['prerequisitos'] ??
        map['prerequisito'] ??
        map['requires'];

    if (raw == null) return const <String>[];

    if (raw is List) {
      return raw
          .map((item) => _normalizeTechId(item.toString()))
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    }

    if (raw is String) {
      final id = _normalizeTechId(raw);
      return id.isEmpty ? const <String>[] : <String>[id];
    }

    if (raw is Map) {
      final out = <String>[];
      for (final entry in raw.entries) {
        final id = _normalizeTechId(entry.key.toString());
        if (id.isEmpty) continue;

        final value = entry.value;
        final enabled =
            value == null || value == true || value == 1 || value == '1';
        if (enabled) out.add(id);
      }
      return out;
    }

    final asText = _normalizeTechId(raw.toString());
    return asText.isEmpty ? const <String>[] : <String>[asText];
  }

  List<TechNodeModel> _buildVisualNodes(
    List<_TechNodeDraft> drafts,
    Map<String, int> prices,
  ) {
    if (drafts.isEmpty) return const <TechNodeModel>[];

    const preferredBranchOrder = <String>[
      'biologica',
      'logistica',
      'artilleria',
    ];
    final discovered = drafts
        .map((node) => node.branchId)
        .toSet()
        .toList(growable: false);

    final branchOrder = <String>[
      ...preferredBranchOrder.where(discovered.contains),
      ...discovered.where((id) => !preferredBranchOrder.contains(id)),
    ];

    const startX = 120.0;
    const startY = 190.0;
    const branchSpacing = 400.0;
    const tierSpacing = 230.0;
    const nodeSpacing = 190.0;

    final nodes = <TechNodeModel>[];
    final seen = <String>{};

    for (var branchIndex = 0; branchIndex < branchOrder.length; branchIndex++) {
      final branchId = branchOrder[branchIndex];
      final branchDrafts = drafts.where((draft) => draft.branchId == branchId);
      final perTier = <int, List<_TechNodeDraft>>{};

      for (final draft in branchDrafts) {
        perTier.putIfAbsent(draft.tier, () => <_TechNodeDraft>[]).add(draft);
      }

      final tiers = perTier.keys.toList()..sort();
      for (final tier in tiers) {
        final row = perTier[tier] ?? const <_TechNodeDraft>[];
        if (row.isEmpty) continue;

        final centerX = startX + (branchIndex * branchSpacing);
        final y = startY + ((tier - 1) * tierSpacing);
        final rowWidth = (row.length - 1) * nodeSpacing;
        final rowStartX = centerX - (rowWidth / 2);

        for (var i = 0; i < row.length; i++) {
          final draft = row[i];
          if (seen.contains(draft.id)) continue;
          seen.add(draft.id);

          final branch = _branchFromId(branchId);
          final name = (draft.name == null || draft.name!.trim().isEmpty)
              ? _prettyName(draft.id)
              : draft.name!.trim();
          final description =
              (draft.description == null || draft.description!.trim().isEmpty)
              ? 'Sin descripcion proporcionada por backend.'
              : draft.description!.trim();
          final cost = prices[draft.id] ?? draft.cost ?? 0;

          nodes.add(
            TechNodeModel(
              id: draft.id,
              name: name,
              description: description,
              tier: draft.tier,
              cost: cost,
              branch: branch,
              icon: _iconForTech(draft.id, branch),
              position: Offset(rowStartX + (i * nodeSpacing), y),
              prerequisites: draft.prerequisites,
            ),
          );
        }
      }
    }

    return nodes;
  }

  TechBranch _branchFromId(String branchId) {
    final normalized = _normalizeTechId(branchId);
    if (normalized.contains('bio')) return TechBranch.biologica;
    if (normalized.contains('art')) return TechBranch.artilleria;
    return TechBranch.operaciones;
  }

  String _prettyName(String id) {
    return _normalizeTechId(id)
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  IconData _iconForTech(String techId, TechBranch branch) {
    switch (_normalizeTechId(techId)) {
      case 'gripe_aviar':
      case 'coronavirus':
        return Icons.coronavirus_outlined;
      case 'vacuna_universal':
        return Icons.shield_outlined;
      case 'fatiga':
        return Icons.hourglass_bottom;
      case 'academia_militar':
        return Icons.account_balance;
      case 'inhibidor_senal':
        return Icons.settings_input_antenna;
      case 'propaganda_subversiva':
        return Icons.campaign_outlined;
      case 'muro_fronterizo':
        return Icons.fence;
      case 'sanciones_internacionales':
        return Icons.public_off;
      case 'mortero_tactico':
        return Icons.construction;
      case 'misil_crucero':
        return Icons.rocket_launch_outlined;
      case 'cabeza_nuclear':
        return Icons.cloud;
      case 'bomba_racimo':
        return Icons.auto_awesome_motion;
      default:
        switch (branch) {
          case TechBranch.biologica:
            return Icons.biotech_outlined;
          case TechBranch.artilleria:
            return Icons.rocket_outlined;
          case TechBranch.operaciones:
            return Icons.hub_outlined;
        }
    }
  }

  String _normalizeTechId(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return normalized.replaceAll(RegExp(r'_+'), '_');
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final raw = value.toString().trim().toLowerCase();
    if (raw.isEmpty) return null;
    if (raw == 'true' || raw == '1' || raw == 'si' || raw == 'yes') {
      return true;
    }
    if (raw == 'false' || raw == '0' || raw == 'no') {
      return false;
    }

    return null;
  }
}

class _TechNodeDraft {
  final String id;
  final String branchId;
  final int tier;
  final String? name;
  final String? description;
  final int? cost;
  final List<String> prerequisites;
  final bool? preUnlocked;
  final bool? owned;

  const _TechNodeDraft({
    required this.id,
    required this.branchId,
    required this.tier,
    required this.name,
    required this.description,
    required this.cost,
    required this.prerequisites,
    required this.preUnlocked,
    required this.owned,
  });

  _TechNodeDraft copyWith({
    String? id,
    String? branchId,
    int? tier,
    String? name,
    String? description,
    int? cost,
    List<String>? prerequisites,
    bool? preUnlocked,
    bool? owned,
  }) {
    return _TechNodeDraft(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      prerequisites: prerequisites ?? this.prerequisites,
      preUnlocked: preUnlocked ?? this.preUnlocked,
      owned: owned ?? this.owned,
    );
  }
}
