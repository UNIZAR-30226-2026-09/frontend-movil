import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/tech_tree_model.dart';

class TechTreeView extends StatefulWidget {
  final List<TechNodeModel> nodes;
  final Size canvasSize;

  static const double _nodeWidth = 150;
  static const double _nodeHeight = 124;

  const TechTreeView({
    super.key,
    required this.nodes,
    required this.canvasSize,
  });

  @override
  State<TechTreeView> createState() => _TechTreeViewState();
}

class _TechTreeViewState extends State<TechTreeView> {
  static const double _baseScale = 1.0;
  static const double _panEnableScaleThreshold = 1.02;

  late final TransformationController _transformController;
  bool _panEnabled = false;

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

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return const Center(
        child: Text(
          'Arbol preparado.\nPendiente de cargar nodos desde el PDF.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          clipBehavior: Clip.hardEdge,
          transformationController: _transformController,
          panEnabled: _panEnabled,
          minScale: _baseScale,
          maxScale: 1.85,
          boundaryMargin: const EdgeInsets.all(20),
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
                        child: _TreeTitleLabel(text: 'INVESTIGACION TECNOLOGICA'),
                      ),
                      const Positioned(
                        top: 100,
                        left: 120,
                        child: _BranchTitleLabel(
                          text: 'GUERRA BIOLOGICA',
                          color: Color(0xFFA8C7F8),
                        ),
                      ),
                      const Positioned(
                        top: 100,
                        left: 520,
                        child: _BranchTitleLabel(
                          text: 'OPERACIONES Y LOGISTICA',
                          color: Color(0xFFD2C6F7),
                        ),
                      ),
                      const Positioned(
                        top: 100,
                        left: 930,
                        child: _BranchTitleLabel(
                          text: 'ARTILLERIA',
                          color: Color(0xFFD9A45B),
                        ),
                      ),
                      ...widget.nodes.map(
                        (node) => Positioned(
                          left: node.position.dx,
                          top: node.position.dy,
                          child: _TechNodeCard(
                            node: node,
                            width: TechTreeView._nodeWidth,
                            height: TechTreeView._nodeHeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TechNodeCard extends StatelessWidget {
  final TechNodeModel node;
  final double width;
  final double height;

  const _TechNodeCard({
    required this.node,
    required this.width,
    required this.height,
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

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.text.withValues(alpha: 0.03),
              border: Border.all(color: AppTheme.textSecondary, width: 1.4),
            ),
            child: Icon(
              node.icon,
              color: AppTheme.text,
              size: 32,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppTheme.textSecondary, width: 1),
            ),
            child: Text(
              node.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 9.8,
                height: 1.1,
              ),
            ),
          ),
        ],
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

class _BranchTitleLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _BranchTitleLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary, width: 1.1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.45,
          fontSize: 11.4,
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

    Offset? centerOf(String id) => centers[id];

    final raiz = Offset(size.width / 2, 68);
    final bioL1 = centerOf('bio_n1');
    final opsL1 = centerOf('ops_n1');
    final artL1 = centerOf('art_n1');

    if (bioL1 != null) canvas.drawLine(raiz, bioL1, linePaint);
    if (opsL1 != null) canvas.drawLine(raiz, opsL1, linePaint);
    if (artL1 != null) canvas.drawLine(raiz, artL1, linePaint);

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
