import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../models/tech_tree_model.dart';
import '../providers/game_provider.dart';

class TechTreeView extends ConsumerStatefulWidget {
  final List<TechNodeModel> nodes;
  final Size canvasSize;
  final Set<String> ownedTechIds;
  final Set<String> unlockedTechIds;
  final String? investigandoId;
  final String? localUsername;
  final void Function(String techId, int cost)? onResearchPressed;

  const TechTreeView({
    super.key,
    required this.nodes,
    required this.canvasSize,
    this.ownedTechIds = const <String>{},
    this.unlockedTechIds = const <String>{},
    this.investigandoId,
    this.localUsername,
    this.onResearchPressed,
  });

  @override
  ConsumerState<TechTreeView> createState() => _TechTreeViewState();
}

class _TechTreeViewState extends ConsumerState<TechTreeView> {
  String? _selectedNodeId;

  void _toggleSelection(String nodeId) {
    setState(() {
      _selectedNodeId = _selectedNodeId == nodeId ? null : nodeId;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNodeId = null;
    });
  }

  TechNodeModel? _selectedNode() {
    final selectedId = _selectedNodeId;
    if (selectedId == null) return null;

    for (final node in widget.nodes) {
      if (node.id == selectedId) return node;
    }

    return null;
  }

  Set<String> get _effectiveOwnedIds {
    final gameState = ref.watch(gameProvider);
    final username = widget.localUsername ?? '';
    final liveOwned = <String>{
      ...(gameState.jugadores[username]?.tecnologiasCompradas ??
          const <String>[]),
    };
    return {...widget.ownedTechIds, ...liveOwned};
  }

  bool _isInvestigating(TechNodeModel node) {
    final id = widget.investigandoId;
    return id != null && id.isNotEmpty && id == node.id;
  }

  bool _isOwned(TechNodeModel node) {
    return _effectiveOwnedIds.contains(node.id);
  }

  bool _isUnlocked(TechNodeModel node) {
    if (_isOwned(node)) return true;
    if (widget.unlockedTechIds.contains(node.id)) return true;
    if (node.prerequisites.isEmpty) return true;

    return node.prerequisites.any(
      (pid) =>
          widget.unlockedTechIds.contains(pid) ||
          _effectiveOwnedIds.contains(pid),
    );
  }

  bool _canResearch(TechNodeModel node) {
    return !_isOwned(node) && !_isInvestigating(node) && _isUnlocked(node);
  }

  String _statusLabel(TechNodeModel node) {
    if (_isInvestigating(node)) return 'Investigando...';
    if (_isOwned(node)) return 'Investigada';
    if (widget.unlockedTechIds.contains(node.id)) return 'Predesbloqueada';
    if (!_isUnlocked(node)) return 'Bloqueada';
    return 'Disponible';
  }

  Color _statusColor(TechNodeModel node) {
    if (_isInvestigating(node)) return const Color(0xFF6AB7E8);
    if (_isOwned(node)) return const Color(0xFF4CD964);
    if (widget.unlockedTechIds.contains(node.id)) {
      return const Color(0xFFFF9040);
    }
    if (!_isUnlocked(node)) return AppTheme.textSecondary;
    return AppTheme.borderGoldVivo;
  }

  String _researchButtonLabel(TechNodeModel node) {
    if (_isInvestigating(node)) return 'Investigando...';
    if (_isOwned(node)) return 'Activo';
    if (!_isUnlocked(node)) return 'Bloqueado';
    if (widget.unlockedTechIds.contains(node.id)) return 'Comprar';
    return 'Investigar';
  }

  List<TechNodeModel> _nodesForBranch(TechBranch branch) {
    return widget.nodes
        .where((node) => node.branch == branch)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return const Center(
        child: Text(
          'No hay habilidades disponibles en el catálogo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
      );
    }

    final selectedNode = _selectedNode();
    final branches = <_TechBranchSpec>[
      _TechBranchSpec(
        branch: TechBranch.biologica,
        title: 'GUERRA BIOLOGICA',
        baseColor: const Color(0xFF1A2F6B),
        completedColor: const Color(0xFF0D1B3E),
      ),
      _TechBranchSpec(
        branch: TechBranch.operaciones,
        title: 'OPERACIONES & LOGISTICA',
        baseColor: const Color(0xFF4A1E7A),
        completedColor: const Color(0xFF2D0D5A),
      ),
      _TechBranchSpec(
        branch: TechBranch.artilleria,
        title: 'ARTILLERIA',
        baseColor: const Color(0xFF7A1A1A),
        completedColor: const Color(0xFF4E0A0A),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: [
              const _TreeTitleLabel(text: 'INVESTIGACION Y DESARROLLO'),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < branches.length; index++) ...[
                      Expanded(
                        child: _TechBranchPanel(
                          spec: branches[index],
                          nodes: _nodesForBranch(branches[index].branch),
                          selectedNodeId: _selectedNodeId,
                          ownedIds: _effectiveOwnedIds,
                          preUnlockedIds: widget.unlockedTechIds,
                          isOwned: _isOwned,
                          isUnlocked: _isUnlocked,
                          isInvestigating: _isInvestigating,
                          onNodeTap: _toggleSelection,
                        ),
                      ),
                      if (index < branches.length - 1)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (selectedNode != null)
          Positioned(
            left: 22,
            right: 22,
            bottom: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _TechNodeTooltip(
                node: selectedNode,
                displayName: selectedNode.name,
                description: selectedNode.description,
                cost: selectedNode.cost,
                statusLabel: _statusLabel(selectedNode),
                statusColor: _statusColor(selectedNode),
                researchButtonLabel: _researchButtonLabel(selectedNode),
                canResearch: _canResearch(selectedNode),
                onResearch: widget.onResearchPressed == null
                    ? null
                    : () => widget.onResearchPressed!(
                        selectedNode.id,
                        selectedNode.cost,
                      ),
                onClose: _clearSelection,
              ),
            ),
          ),
      ],
    );
  }
}

class _TechBranchSpec {
  final TechBranch branch;
  final String title;
  final Color baseColor;
  final Color completedColor;

  const _TechBranchSpec({
    required this.branch,
    required this.title,
    required this.baseColor,
    required this.completedColor,
  });
}

class _TechBranchPanel extends StatelessWidget {
  final _TechBranchSpec spec;
  final List<TechNodeModel> nodes;
  final String? selectedNodeId;
  final Set<String> ownedIds;
  final Set<String> preUnlockedIds;
  final bool Function(TechNodeModel node) isOwned;
  final bool Function(TechNodeModel node) isUnlocked;
  final bool Function(TechNodeModel node) isInvestigating;
  final void Function(String nodeId) onNodeTap;

  const _TechBranchPanel({
    required this.spec,
    required this.nodes,
    required this.selectedNodeId,
    required this.ownedIds,
    required this.preUnlockedIds,
    required this.isOwned,
    required this.isUnlocked,
    required this.isInvestigating,
    required this.onNodeTap,
  });

  bool get _branchCompleted {
    return nodes.isNotEmpty &&
        nodes.every(
          (node) =>
              ownedIds.contains(node.id) || preUnlockedIds.contains(node.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (_branchCompleted ? spec.completedColor : spec.baseColor)
            .withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGoldVivo, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const headerHeight = 54.0;
          final layout = _BranchLayoutCalculator.calculate(
            nodes: nodes,
            size: Size(constraints.maxWidth, constraints.maxHeight),
            headerHeight: headerHeight,
          );

          return Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 0,
                height: headerHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      spec.title,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1.4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderGoldVivo.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _BranchConnectionsPainter(layouts: layout),
                ),
              ),
              for (final item in layout)
                Positioned.fromRect(
                  rect: item.rect,
                  child: _TechNodeCard(
                    node: item.node,
                    displayName: _compactNodeName(item.node.name),
                    isSelected: item.node.id == selectedNodeId,
                    isOwned: isOwned(item.node),
                    isUnlocked: isUnlocked(item.node),
                    isPreUnlocked: preUnlockedIds.contains(item.node.id),
                    isInvestigating: isInvestigating(item.node),
                    onTap: () => onNodeTap(item.node.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _compactNodeName(String raw) {
    return raw.replaceFirst(
      RegExp(r'^NIVEL\s+\d+[A-Z]?:\s*', caseSensitive: false),
      '',
    );
  }
}

class _BranchNodeLayout {
  final TechNodeModel node;
  final Rect rect;

  const _BranchNodeLayout({required this.node, required this.rect});

  Offset get topCenter => Offset(rect.center.dx, rect.top);
  Offset get bottomCenter => Offset(rect.center.dx, rect.bottom);
}

class _BranchLayoutCalculator {
  static List<_BranchNodeLayout> calculate({
    required List<TechNodeModel> nodes,
    required Size size,
    required double headerHeight,
  }) {
    if (nodes.isEmpty || size.width <= 0 || size.height <= headerHeight) {
      return const <_BranchNodeLayout>[];
    }

    final perTier = <int, List<TechNodeModel>>{};
    for (final node in nodes) {
      perTier.putIfAbsent(node.tier, () => <TechNodeModel>[]).add(node);
    }

    final tiers = perTier.keys.toList()..sort();
    final maxItemsInTier = perTier.values.fold<int>(
      1,
      (max, row) => math.max(max, row.length),
    );

    final horizontalPadding = size.width < 280 ? 12.0 : 24.0;
    final availableWidth = size.width - (horizontalPadding * 2);
    final nodeWidth = math.min(
      108.0,
      math.max(
        74.0,
        (availableWidth - ((maxItemsInTier - 1) * 18)) / maxItemsInTier,
      ),
    );
    final nodeHeight = math.min(66.0, math.max(56.0, size.height * 0.098));

    final contentTop = headerHeight + 14;
    final contentBottom = size.height - 14;
    final contentHeight = math.max(nodeHeight, contentBottom - contentTop);
    final gap = tiers.length <= 1 ? 0.0 : contentHeight / (tiers.length - 1);

    final output = <_BranchNodeLayout>[];
    for (var tierIndex = 0; tierIndex < tiers.length; tierIndex++) {
      final row = perTier[tiers[tierIndex]] ?? const <TechNodeModel>[];
      final rowWidth = (row.length * nodeWidth) + ((row.length - 1) * 18);
      final rowStartX = (size.width - rowWidth) / 2;
      final centerY = tiers.length == 1
          ? contentTop + (contentHeight / 2)
          : contentTop + (gap * tierIndex);
      final top = (centerY - (nodeHeight / 2))
          .clamp(contentTop, math.max(contentTop, contentBottom - nodeHeight))
          .toDouble();

      for (var i = 0; i < row.length; i++) {
        final left = (rowStartX + (i * (nodeWidth + 18))).toDouble();
        output.add(
          _BranchNodeLayout(
            node: row[i],
            rect: Rect.fromLTWH(left, top, nodeWidth, nodeHeight),
          ),
        );
      }
    }

    return output;
  }
}

class _TechNodeCard extends StatelessWidget {
  final TechNodeModel node;
  final String displayName;
  final bool isSelected;
  final bool isOwned;
  final bool isUnlocked;
  final bool isPreUnlocked;
  final bool isInvestigating;
  final VoidCallback onTap;

  const _TechNodeCard({
    required this.node,
    required this.displayName,
    required this.isSelected,
    required this.isOwned,
    required this.isUnlocked,
    required this.isPreUnlocked,
    required this.isInvestigating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !isOwned && !isUnlocked;
    final fillColor = _fillColor(locked);
    final borderColor = _borderColor(locked);
    final iconOpacity = locked ? 0.6 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : borderColor,
            width: isSelected ? 2.2 : 1.7,
          ),
          boxShadow: [
            if (isOwned)
              BoxShadow(
                color: const Color(0xFF4CD964).withValues(alpha: 0.34),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            if (isSelected)
              BoxShadow(
                color: AppTheme.borderGoldVivo.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: iconOpacity,
                    child: Icon(node.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Center(
                      child: Text(
                        displayName,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked
                              ? Colors.white.withValues(alpha: 0.62)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 8.1,
                          height: 1.02,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -7,
              right: -7,
              child: _NodeStatusBadge(
                isOwned: isOwned,
                isPreUnlocked: isPreUnlocked,
                isInvestigating: isInvestigating,
                locked: locked,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _fillColor(bool locked) {
    if (isOwned) return const Color(0xFF28A745).withValues(alpha: 0.94);
    if (isPreUnlocked || isInvestigating) {
      return const Color(0xFFE07020).withValues(alpha: 0.94);
    }
    if (locked) return const Color(0xFF66666B).withValues(alpha: 0.78);
    return AppTheme.goldMain.withValues(alpha: 0.86);
  }

  Color _borderColor(bool locked) {
    if (isOwned) return const Color(0xFF4CD964);
    if (isPreUnlocked || isInvestigating) return const Color(0xFFFF9040);
    if (locked) return const Color(0xFFAAAAAA).withValues(alpha: 0.78);
    return AppTheme.borderGoldVivo;
  }
}

class _NodeStatusBadge extends StatelessWidget {
  final bool isOwned;
  final bool isPreUnlocked;
  final bool isInvestigating;
  final bool locked;

  const _NodeStatusBadge({
    required this.isOwned,
    required this.isPreUnlocked,
    required this.isInvestigating,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (isOwned) {
      icon = Icons.check_rounded;
      color = const Color(0xFF23D18B);
    } else if (isInvestigating) {
      icon = Icons.hourglass_top_rounded;
      color = const Color(0xFF6AB7E8);
    } else if (isPreUnlocked) {
      icon = Icons.shopping_cart_checkout_rounded;
      color = const Color(0xFFFF9040);
    } else if (locked) {
      icon = Icons.lock_rounded;
      color = const Color(0xFFAAAAAA);
    } else {
      icon = Icons.science_rounded;
      color = AppTheme.borderGoldVivo;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.4),
      ),
      child: Icon(icon, color: color, size: 12),
    );
  }
}

class _TechNodeTooltip extends StatelessWidget {
  final TechNodeModel node;
  final String displayName;
  final String description;
  final int cost;
  final String statusLabel;
  final Color statusColor;
  final String researchButtonLabel;
  final bool canResearch;
  final VoidCallback? onResearch;
  final VoidCallback onClose;

  const _TechNodeTooltip({
    required this.node,
    required this.displayName,
    required this.description,
    required this.cost,
    required this.statusLabel,
    required this.statusColor,
    required this.researchButtonLabel,
    required this.canResearch,
    required this.onResearch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppTheme.bg.withValues(alpha: 0.97),
            border: Border.all(color: AppTheme.borderGoldVivo, width: 1.4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    iconSize: 18,
                    splashRadius: 18,
                    color: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TooltipChip(
                    label: 'Nivel ${node.tier}',
                    color: AppTheme.primary,
                  ),
                  _TooltipChip(label: 'Coste $cost', color: AppTheme.primary),
                  _TooltipChip(label: statusLabel, color: statusColor),
                  _TooltipChip(
                    label: node.prerequisites.isEmpty
                        ? 'Sin prerequisitos'
                        : 'Pre: ${node.prerequisites.length}',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 13.5,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canResearch ? onResearch : null,
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: Text(researchButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TooltipChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TooltipChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TreeTitleLabel extends StatelessWidget {
  final String text;

  const _TreeTitleLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppTheme.borderGoldVivo,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
        fontSize: 20,
      ),
    );
  }
}

class _BranchConnectionsPainter extends CustomPainter {
  final List<_BranchNodeLayout> layouts;

  const _BranchConnectionsPainter({required this.layouts});

  @override
  void paint(Canvas canvas, Size size) {
    final byId = <String, _BranchNodeLayout>{
      for (final layout in layouts) layout.node.id: layout,
    };

    final paint = Paint()
      ..color = AppTheme.goldMain.withValues(alpha: 0.74)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final layout in layouts) {
      for (final prereqId in layout.node.prerequisites) {
        final parent = byId[prereqId];
        if (parent == null) continue;

        final start = parent.bottomCenter;
        final end = layout.topCenter;
        final path = Path()
          ..moveTo(start.dx, start.dy + 4)
          ..lineTo((start.dx + end.dx) / 2, (start.dy + end.dy) / 2)
          ..lineTo(end.dx, end.dy - 4);

        _drawDashedPath(canvas, path, paint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BranchConnectionsPainter oldDelegate) {
    return oldDelegate.layouts != layouts;
  }
}
