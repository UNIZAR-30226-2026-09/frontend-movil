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

  static const double _nodeWidth = 180;
  static const double _nodeHeight = 155;

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
  static const double _baseScale = 1.0;
  static const double _panEnableScaleThreshold = 1.02;

  late final TransformationController _transformController;
  bool _panEnabled = false;
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(_handleTransformChange);
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransformChange);
    _transformController.dispose();
    super.dispose();
  }

  void _handleTransformChange() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final shouldEnablePan = scale > _panEnableScaleThreshold;
    if (shouldEnablePan != _panEnabled) {
      setState(() {
        _panEnabled = shouldEnablePan;
      });
    }
  }

  void _resetIfNearBaseScale() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale <= _panEnableScaleThreshold) {
      _transformController.value = Matrix4.identity();
    }
  }

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

  // ---------------------------------------------------------------------------
  // Cascada de estados (orden de prioridad):
  //   1. INVESTIGANDO  – el jugador está investigando ese nodo ahora mismo.
  //   2. COMPRADA      – el nodo está en tecnologias_compradas.
  //   3. PREDESBLOQUEADA – el nodo está en tecnologias_predesbloqueadas.
  //   4. INVESTIGABLE  – sin prerrequisito, O el padre está predesbloqueado/comprado.
  //   5. BLOQUEADA     – cualquier otro caso.
  // ---------------------------------------------------------------------------

  bool _isInvestigating(TechNodeModel node) {
    final id = widget.investigandoId;
    return id != null && id.isNotEmpty && id == node.id;
  }

  /// Retorna el conjunto de IDs comprados fusionando los props con el estado reactivo.
  Set<String> get _effectiveOwnedIds {
    final gameState = ref.watch(gameProvider);
    final username = widget.localUsername ?? '';
    final liveOwned = <String>{
      ...(gameState.jugadores[username]?.tecnologiasCompradas ?? const <String>[]),
    };
    return {...widget.ownedTechIds, ...liveOwned};
  }

  bool _isOwned(TechNodeModel node) {
    return _effectiveOwnedIds.contains(node.id);
  }

  /// Un nodo está "desbloqueado" (disponible para investigar) si:
  ///   - No tiene prerrequisitos (nodo raíz), o
  ///   - Al menos uno de sus prerrequisitos está en predesbloqueadas o compradas.
  bool _isUnlocked(TechNodeModel node) {
    if (_isOwned(node)) return true;
    if (widget.unlockedTechIds.contains(node.id)) return true;
    // Nodo raíz: investigable directamente.
    if (node.prerequisites.isEmpty) return true;
    // Al menos un padre investigado (predesbloqueado o comprado).
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
    if (_isInvestigating(node)) return 'Investigando…';
    if (_isOwned(node)) return 'Investigada';
    if (widget.unlockedTechIds.contains(node.id)) return 'Predesbloqueada';
    if (!_isUnlocked(node)) return 'Bloqueada';
    return 'Disponible';
  }

  Color _statusColor(TechNodeModel node) {
    if (_isInvestigating(node)) return const Color(0xFF6AB7E8);
    if (_isOwned(node)) return const Color(0xFF74D67A);
    if (widget.unlockedTechIds.contains(node.id)) return const Color(0xFFE6C36A);
    if (!_isUnlocked(node)) return AppTheme.textSecondary;
    return const Color(0xFFE6C36A);
  }

  String _researchButtonLabel(TechNodeModel node) {
    if (_isInvestigating(node)) return 'Investigando…';
    if (_isOwned(node)) return 'Ya investigada';
    if (!_isUnlocked(node)) return 'Bloqueada por prerrequisitos';
    return 'Investigar';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedNode = _selectedNode();

        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                clipBehavior: Clip.hardEdge,
                transformationController: _transformController,
                panEnabled: _panEnabled,
                minScale: _baseScale,
                maxScale: 1.85,
                boundaryMargin: const EdgeInsets.all(40),
                onInteractionEnd: (_) => _resetIfNearBaseScale(),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: widget.canvasSize.width,
                        height: widget.canvasSize.height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TechConnectionsPainter(
                                  nodes: widget.nodes,
                                  nodeWidth: TechTreeView._nodeWidth,
                                  nodeHeight: TechTreeView._nodeHeight,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 20,
                              left: 430,
                              child: _TreeTitleLabel(
                                text: 'INVESTIGACION TECNOLOGICA',
                              ),
                            ),
                            ...widget.nodes.map(
                              (node) => Positioned(
                                left: node.position.dx,
                                top: node.position.dy,
                                child: _TechNodeCard(
                                  node: node,
                                  displayName: node.name,
                                  width: TechTreeView._nodeWidth,
                                  height: TechTreeView._nodeHeight,
                                  isSelected: node.id == _selectedNodeId,
                                  isOwned: _isOwned(node),
                                  isUnlocked: _isUnlocked(node),
                                  isPreUnlocked: widget.unlockedTechIds.contains(node.id),
                                  onTap: () => _toggleSelection(node.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selectedNode != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
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
          ],
        );
      },
    );
  }
}

class _TechNodeCard extends StatelessWidget {
  final TechNodeModel node;
  final String displayName;
  final double width;
  final double height;
  final bool isSelected;
  final bool isOwned;
  final bool isUnlocked;
  final bool isPreUnlocked;
  final VoidCallback onTap;

  const _TechNodeCard({
    required this.node,
    required this.displayName,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.isOwned,
    required this.isUnlocked,
    this.isPreUnlocked = false,
    required this.onTap,
  });

  Color _branchColor(TechBranch branch) {
    switch (branch) {
      case TechBranch.biologica:
        return const Color(0xFFA8C7F8);
      case TechBranch.operaciones:
        return const Color(0xFFD2C6F7);
      case TechBranch.artilleria:
        return const Color(0xFFD9A45B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _branchColor(node.branch);
    final locked = !isOwned && !isUnlocked;
    final effectiveAccent = locked
        ? AppTheme.textSecondary.withValues(alpha: 0.6)
        : (isOwned ? const Color(0xFF74D67A) : accent);

    // Color de fondo del contenedor del icono según estado:
    // Verde neón  → comprada/investigada.
    // Naranja vivo → predesbloqueada (investigada pero pendiente de pago).
    // Gris/neutro  → bloqueada o solo investigable.
    final Color iconBgColor;
    final Color iconColor;
    if (isOwned) {
      iconBgColor = const Color(0xFF00E676).withValues(alpha: 0.55); // verde neón
      iconColor = const Color(0xFF003319);
    } else if (isPreUnlocked) {
      iconBgColor = const Color(0xFFFF9100).withValues(alpha: 0.60); // naranja vivo
      iconColor = const Color(0xFF2D1800);
    } else {
      iconBgColor = AppTheme.text.withValues(
        alpha: locked ? 0.015 : (isSelected ? 0.09 : 0.03),
      );
      iconColor = locked ? AppTheme.textSecondary : AppTheme.text;
    }

    // Color del texto: siempre blanco para máximo contraste sobre cualquier fondo.
    const Color nameColor = Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: iconBgColor,
                border: Border.all(
                  color: isSelected ? effectiveAccent : AppTheme.textSecondary,
                  width: isSelected ? 2.1 : 1.4,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: effectiveAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                node.icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? effectiveAccent.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? effectiveAccent : AppTheme.textSecondary,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Text(
                displayName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17.0,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Color _branchColor(TechBranch branch) {
    switch (branch) {
      case TechBranch.biologica:
        return const Color(0xFFA8C7F8);
      case TechBranch.operaciones:
        return const Color(0xFFD2C6F7);
      case TechBranch.artilleria:
        return const Color(0xFFD9A45B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _branchColor(node.branch);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppTheme.bg.withValues(alpha: 0.96),
            border: Border.all(color: accent, width: 1.2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.0,
                        height: 1.15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    iconSize: 18,
                    splashRadius: 18,
                    color: AppTheme.textSecondary,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TooltipChip(label: 'Nivel ${node.tier}', color: accent),
                  _TooltipChip(label: 'Coste $cost', color: accent),
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
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  height: 1.4,
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
          fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary, width: 1.2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.text,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontSize: 21,
        ),
      ),
    );
  }
}

class _TechConnectionsPainter extends CustomPainter {
  final List<TechNodeModel> nodes;
  final double nodeWidth;
  final double nodeHeight;

  const _TechConnectionsPainter({
    required this.nodes,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.62)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centers = <String, Offset>{
      for (final node in nodes)
        node.id: Offset(
          node.position.dx + nodeWidth / 2,
          node.position.dy + 36,
        ),
    };

    final raiz = Offset(size.width / 2, 68);

    final nivelBase = nodes
        .where((node) => node.prerequisites.isEmpty)
        .map((node) => centers[node.id])
        .whereType<Offset>();

    for (final start in nivelBase) {
      canvas.drawLine(raiz, start, linePaint);
    }

    for (final node in nodes) {
      final end = centers[node.id];
      if (end == null) continue;

      for (final prereqId in node.prerequisites) {
        final start = centers[prereqId];
        if (start == null) continue;

        final path = Path()
          ..moveTo(start.dx, start.dy + 38)
          ..lineTo(start.dx, (start.dy + end.dy) / 2)
          ..lineTo(end.dx, (start.dy + end.dy) / 2)
          ..lineTo(end.dx, end.dy - 38);

        canvas.drawPath(path, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TechConnectionsPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}
