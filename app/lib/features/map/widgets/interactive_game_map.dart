import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:vector_math/vector_math_64.dart';
import '../services/map_loader.dart';
import '../services/map_painter.dart';
import '../models/territory_model.dart';
import '../config/map_data.dart';
import '../../game/providers/game_provider.dart'; 

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

  bool _isClamping = false;
  Size? _lastViewportSize;

  TransformationController get _tc => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownsController = true;
      _internalController = TransformationController();
    }
    _currentScale = _tc.value.storage[0];
    _tc.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _tc.removeListener(_handleTransformChanged);
    if (_ownsController) _internalController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    if (_isClamping) return;
    if (_lastViewportSize == null) return;

    _isClamping = true;
    _clampToViewport(_lastViewportSize!);
    _isClamping = false;
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
        _lastViewportSize = viewport;

        return InteractiveViewer(
          transformationController: _tc,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          panEnabled: panAllowed,
          boundaryMargin: EdgeInsets.zero,
          constrained: true,
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

  

  double _getScale(Matrix4 m) {
    return m.storage[0];
  }
  
  Offset _getTranslation(Matrix4 m) {
    return Offset(m.storage[12], m.storage[13]);
  }
  
  Matrix4 _setTranslation(Matrix4 m, Offset t) {
    final next = Matrix4.copy(m);
    next.storage[12] = t.dx;
    next.storage[13] = t.dy;
    return next;
  }

  double _applyResistance(double value, double min, double max) {
    if (value < min) {
      final overshoot = min - value;
      final resisted = overshoot / (1.0 + overshoot / 60.0);
      return min - resisted;
    }

    if (value > max) {
      final overshoot = value - max;
      final resisted = overshoot / (1.0 + overshoot / 60.0);
      return max + resisted;
    }

    return value;
  }

  bool _isOutsideBounds(double value, double min, double max) {
    return value < min || value > max;
  }

  void _clampToViewport(Size viewportSize) {
    final m = _tc.value;
    final s = _getScale(m);

    final vw = viewportSize.width;
    final vh = viewportSize.height;

    double tx = m.storage[12];
    double ty = m.storage[13];

    // Si estamos en zoom mínimo, bloqueado
    if (s <= widget.minScale + _eps) {
      final locked = Matrix4.identity()..scale(widget.minScale);
      _tc.value = locked;

      if ((_currentScale - widget.minScale).abs() > 1e-4) {
        setState(() => _currentScale = widget.minScale);
      }
      return;
    }

    // Rectángulo REAL del mapa dentro del child
    final scaleX = vw / MapPaths.viewBoxWidth;
    final scaleY = vh / MapPaths.viewBoxHeight;
    final baseScale = scaleX < scaleY ? scaleX : scaleY;

    final scaledW = MapPaths.viewBoxWidth * baseScale;
    final scaledH = MapPaths.viewBoxHeight * baseScale;

    final dx = (vw - scaledW) / 2.0;
    final dy = (vh - scaledH) / 2.0;
    final extraUp = vh * 0.05;

    final mapLeft = dx;
    final mapTop = dy - extraUp;
    final mapRight = dx + scaledW;
    final mapBottom = dy - extraUp + scaledH;

    final mapW = scaledW * s;
    final mapH = scaledH * s;

    // Horizontal
    bool outsideX = false;

    if (mapW <= vw) {
      tx = (vw - mapW) / 2.0 - mapLeft * s;
    } else {
      final minTx = vw - mapRight * s;
      final maxTx = -mapLeft * s;
      outsideX = _isOutsideBounds(tx, minTx, maxTx);
      tx = _applyResistance(tx, minTx, maxTx);
    }

    bool outsideY = false;

    if (mapH <= vh) {
      ty = (vh - mapH) / 2.0 - mapTop * s;
    } else {
      final minTy = vh - mapBottom * s;
      final maxTy = -mapTop * s;
      outsideY = _isOutsideBounds(ty, minTy, maxTy);
      ty = _applyResistance(ty, minTy, maxTy);
    }

    final current = _getTranslation(m);
    final target = Offset(tx, ty);
    
    Offset finalOffset;
    
    if (outsideX || outsideY) {
      const smooth = 0.2;
      finalOffset = Offset(
        current.dx + (target.dx - current.dx) * smooth,
        current.dy + (target.dy - current.dy) * smooth,
      );
    } else {
      finalOffset = target;
    }
    
    final clamped = _setTranslation(m, finalOffset);
    _tc.value = clamped;
    
    final newScale = _getScale(_tc.value);
    if ((newScale - _currentScale).abs() > 1e-4) {
      setState(() => _currentScale = newScale);
    }
  }
}