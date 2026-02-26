import 'dart:math' as math;
import 'dart:ui' as ui show Offset;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../services/map_loader.dart';   // GameMap
import '../services/map_painter.dart';  // MapPainter
import '../models/territory_model.dart';
import '../config/map_data.dart';


typedef OnTapComarca = void Function(Comarca comarca);

class InteractiveGameMap extends StatefulWidget {
  final TransformationController? controller;
  final GameMap gameMap;

  final double minScale;
  final double maxScale;
  final EdgeInsets boundaryMargin;

  final OnTapComarca? onTapComarca;

  const InteractiveGameMap({
    super.key,
    required this.gameMap,
    this.controller,
    this.onTapComarca,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.boundaryMargin = const EdgeInsets.all(200),
  });

  @override
  State<InteractiveGameMap> createState() => _InteractiveGameMapState();
}

class _InteractiveGameMapState extends State<InteractiveGameMap> {
  String? _selectedComarcaId;
  late final TransformationController _internalController;
  bool _ownsController = false;

  TransformationController get _tc => widget.controller ?? _internalController;

  // Para poder activar/desactivar pan según escala
  double _currentScale = 1.0;
  static const double _eps = 1e-6;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownsController = true;
      _internalController = TransformationController();
    }
    _currentScale = _getScale(_tc.value);
  }

  @override
  void dispose() {
    if (_ownsController) _internalController.dispose();
    super.dispose();
  }

  double _getScale(Matrix4 m) {
    // Si solo hay scale + translate, m[0] es el scale en X
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

  void _clampToViewport(Size viewportSize) {
    final m = _tc.value;
    final s = _getScale(m);

    final vw = viewportSize.width;
    final vh = viewportSize.height;

    final cw = vw * s;
    final ch = vh * s;

    final t = _getTranslation(m);
    double tx = t.dx;
    double ty = t.dy;

    // Si estás en escala "normal", no se mueve nada
    if (s <= widget.minScale + _eps) {
      // Como child == viewport, en scale=1 lo correcto es 0,0
      final locked = Matrix4.identity()..scale(widget.minScale);
      _tc.value = locked;
      if (_currentScale != widget.minScale) {
        setState(() => _currentScale = widget.minScale);
      }
      return;
    }

    // Con zoom, nunca permitir "vacío" en pantalla
    // Queremos que el contenido (el child escalado) siempre cubra el viewport.
    // Eso implica: tx <= 0 y tx + cw >= vw  =>  tx in [vw - cw, 0]
    // Si cw < vw (raro si s>1, pero por si acaso), centramos.
    if (cw <= vw) {
      tx = (vw - cw) / 2.0;
    } else {
      final minTx = vw - cw;
      final maxTx = 0.0;
      tx = tx.clamp(minTx, maxTx);
    }

    if (ch <= vh) {
      ty = (vh - ch) / 2.0;
    } else {
      final minTy = vh - ch;
      final maxTy = 0.0;
      ty = ty.clamp(minTy, maxTy);
    }

    final clamped = _setTranslation(m, Offset(tx, ty));
    if (clamped != m) {
      _tc.value = clamped;
    }

    // Actualiza estado para panEnabled
    final newScale = _getScale(_tc.value);
    if ((newScale - _currentScale).abs() > 1e-4) {
      setState(() => _currentScale = newScale);
    }
  }

  // Convierte un punto de pantalla -> punto del mundo (mapa) usando la inversa
  Offset _toScene(Offset localPoint) {
    final matrix = _tc.value;
    final inverseMatrix = Matrix4.inverted(matrix);

    final v = Vector3(localPoint.dx, localPoint.dy, 0);
    final transformed = inverseMatrix.transform3(v);
    return Offset(transformed.x, transformed.y);
  }

  Comarca? _hitTestComarca(Offset mapPoint) {
    for (final comarca in widget.gameMap.comarcas.reversed) {
      final path = widget.gameMap.comarcaPaths[comarca.id];
      if (path == null) continue;

      if (path.contains(mapPoint)) {
        return comarca;
      }
    }
    return null;
  }

  Matrix4 _painterMatrix(Size size) {
    final scaleX = size.width / MapPaths.viewBoxWidth;
    final scaleY = size.height / MapPaths.viewBoxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final scaledW = MapPaths.viewBoxWidth * scale;
    final scaledH = MapPaths.viewBoxHeight * scale;

    final dx = (size.width - scaledW) / 2.0;
    final dy = (size.height - scaledH) / 2.0;
    final extraUp = size.height * 0.05;

    return Matrix4.identity()
      ..translate(dx, dy - extraUp)
      ..scale(scale)
      ..translate(-MapPaths.viewBoxX, -MapPaths.viewBoxY);
  }

  Offset _sceneToMap(Offset scenePoint, Size viewport) {
    final m = _painterMatrix(viewport);
    final inv = Matrix4.inverted(m);

    final v = Vector3(scenePoint.dx, scenePoint.dy, 0);
    final out = inv.transform3(v);
    return Offset(out.x, out.y);
  } 

  @override
  Widget build(BuildContext context) {
    final panAllowed = _currentScale > widget.minScale + _eps;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);

        return InteractiveViewer(
          transformationController: _tc,
          minScale: widget.minScale,
          maxScale: widget.maxScale,

          // Si no hay zoom, pan desactivado
          panEnabled: panAllowed,

          // Esto ayuda a que no “se vaya” por inercia rara.
          boundaryMargin: EdgeInsets.zero,
          constrained: true,

          onInteractionStart: (_) {
            _currentScale = _getScale(_tc.value);
            setState(() {});
          },
          onInteractionUpdate: (_) {
            // Después de cada gesto, recortamos a límites
            _clampToViewport(viewport);
          },
          onInteractionEnd: (_) {
            // Al soltar, por si quedó 1 frame fuera
            _clampToViewport(viewport);
          },

          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                // Punto en coords locales del widget (antes de transformar)
                final local = details.localPosition;

                // Lo pasamos a coords del mapa (deshaciendo zoom/pan)
                final scene = _toScene(local);

                final mapPoint = _sceneToMap(local, viewport);

                final hit = _hitTestComarca(mapPoint);
                if (hit != null) {
                  setState(() {
                    _selectedComarcaId = hit.id;
                  });
                  widget.onTapComarca?.call(hit);
                }
              },
              child: CustomPaint(
                painter: MapPainter(
                  comarcas: widget.gameMap.comarcas,
                  comarcaPaths: widget.gameMap.comarcaPaths,
                  selectedComarcaId: _selectedComarcaId,
                  viewerScale: _currentScale,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}