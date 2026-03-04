import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:vector_math/vector_math_64.dart';
import '../services/map_loader.dart';
import '../services/map_painter.dart';
import '../models/territory_model.dart';
import '../config/map_data.dart';
import '../providers/game_provider.dart'; 

typedef OnTapComarca = void Function(Comarca comarca);

class InteractiveGameMap extends ConsumerStatefulWidget {
  final TransformationController? controller;
  final GameMap gameMap;
  final double minScale;
  final double maxScale;
  final OnTapComarca? onTapComarca;

  const InteractiveGameMap({
    super.key,
    required this.gameMap,
    this.controller,
    this.onTapComarca,
    this.minScale = 1.0,
    this.maxScale = 5.0,
  });

  @override
  ConsumerState<InteractiveGameMap> createState() => _InteractiveGameMapState();
}

class _InteractiveGameMapState extends ConsumerState<InteractiveGameMap> {
  late final TransformationController _internalController;
  bool _ownsController = false;
  double _currentScale = 1.0;
  static const double _eps = 1e-6;

  TransformationController get _tc => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownsController = true;
      _internalController = TransformationController();
    }
    _currentScale = _tc.value.storage[0];
  }

  @override
  void dispose() {
    if (_ownsController) _internalController.dispose();
    super.dispose();
  }


  Comarca? _hitTestComarca(Offset mapPoint) {
    for (final comarca in widget.gameMap.comarcas.reversed) {
      final path = widget.gameMap.comarcaPaths[comarca.id];
      if (path == null) continue;
      if (path.contains(mapPoint)) return comarca;
    }
    return null;
  }

  Offset _sceneToMap(Offset scenePoint, Size viewport) {
    final scaleX = viewport.width / MapPaths.viewBoxWidth;
    final scaleY = viewport.height / MapPaths.viewBoxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (viewport.width - (MapPaths.viewBoxWidth * scale)) / 2.0;
    final dy = (viewport.height - (MapPaths.viewBoxHeight * scale)) / 2.0;
    final extraUp = viewport.height * 0.05;

    // ignore: deprecated_member_use
    final m = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(dx, dy - extraUp)
      // ignore: deprecated_member_use
      ..scale(scale)
      // ignore: deprecated_member_use
      ..translate(-MapPaths.viewBoxX, -MapPaths.viewBoxY);
    
    final inv = Matrix4.inverted(m);
    final v = Vector3(scenePoint.dx, scenePoint.dy, 0);
    final out = inv.transform3(v);
    return Offset(out.x, out.y);
  }

  @override
  Widget build(BuildContext context) {
    // 5. ESCUCHAMOS EL ESTADO DEL JUEGO (T43)
    final gameState = ref.watch(gameProvider); 
    final panAllowed = _currentScale > widget.minScale + _eps;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);

        return InteractiveViewer(
          transformationController: _tc,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          panEnabled: panAllowed,
          boundaryMargin: EdgeInsets.zero,
          onInteractionUpdate: (_) => _clampToViewport(viewport),
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final mapPoint = _sceneToMap(details.localPosition, viewport);
                final hit = _hitTestComarca(mapPoint);
                
                if (hit != null) {
                  // 6. LLAMAMOS AL PROVIDER PARA SELECCIONAR (BFS)
                  ref.read(gameProvider.notifier).seleccionarComarca(hit.id);
                  widget.onTapComarca?.call(hit);
                }
              },
              child: CustomPaint(
                painter: MapPainter(
                  comarcas: widget.gameMap.comarcas,
                  comarcaPaths: widget.gameMap.comarcaPaths,
                  // 7. PASAMOS EL ESTADO COMPLETO AL PAINTER
                  gameState: gameState, 
                  viewerScale: _currentScale,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _clampToViewport(Size viewportSize) {
    // ... (Mantenemos tu lógica de clamp intacta) ...
    final newScale = _tc.value.storage[0];
    if ((newScale - _currentScale).abs() > 1e-4) {
      setState(() => _currentScale = newScale);
    }
  }
}