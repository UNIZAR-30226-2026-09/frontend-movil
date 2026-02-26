import 'dart:ui' show Path;

import 'package:flutter/material.dart';
import '../config/map_data.dart';
import '../models/territory_model.dart';
import '../config/map_colors.dart';

class MapPainter extends CustomPainter {
  final List<Comarca> comarcas;
  final Map<String, Path> comarcaPaths;
  final String? selectedComarcaId;

  final double viewerScale;
  final double labelMinScale;
  final double labelFontSizePx;

  MapPainter({
    required this.comarcas,
    required this.comarcaPaths,
    this.selectedComarcaId,
    required this.viewerScale,
    this.labelMinScale = 2.0,
    this.labelFontSizePx = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;

    
    final baseStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF333333);

    final selectedStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white;

    final selectedFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.15);

    // Escala + translate
    final scaleX = size.width / MapPaths.viewBoxWidth;
    final scaleY = size.height / MapPaths.viewBoxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final ScaledW = MapPaths.viewBoxWidth * scale;
    final ScaledH = MapPaths.viewBoxHeight * scale;

    final dx = (size.width - ScaledW) / 2.0;
    final dy = (size.height - ScaledH) / 2.0;
    final extraUp = size.height * 0.05; // 5% de la altura

    canvas.save();
    canvas.translate(dx, dy - extraUp);
    canvas.scale(scale);
    canvas.translate(-MapPaths.viewBoxX, -MapPaths.viewBoxY);

     // 1) Pinta todas normal
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      fillPaint.color =
          MapColors.comarcaFill[comarca.id] ?? MapColors.fallbackFill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, baseStroke);
    }

    // 2) Pinta el borde seleccionado AL FINAL (encima de todo)
    if (selectedComarcaId != null) {
      final selectedPath = comarcaPaths[selectedComarcaId!];
      if (selectedPath != null) {
        canvas.drawPath(selectedPath, selectedStroke);
        canvas.drawPath(selectedPath, selectedFill);
      }
    }

    // 3) Labels (antes del restore)
    if (viewerScale >= labelMinScale) {
      // para hacer fade-in suave al entrar
      final t = ((viewerScale - labelMinScale) / 0.5).clamp(0.0, 1.0);

      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      );

      // Tamaño constante en pantalla (px)
      // Canvas ya está en coords "mundo" (SVG). En pantalla se multiplica por: scale * viewerScale
      final fontWorld = labelFontSizePx / (scale * viewerScale);

      // también padding/radius constantes en pantalla
      final padX = 6.0 / (scale * viewerScale);
      final padY = 4.0 / (scale * viewerScale);
      final radius = 6.0 / (scale * viewerScale);

      for (final comarca in comarcas) {
        final path = comarcaPaths[comarca.id];
        if (path == null) continue;

        final bounds = path.getBounds();
        if (bounds.width < 25 || bounds.height < 15) continue;

        final center = bounds.center;

        textPainter.text = TextSpan(
          text: comarca.name,
          style: TextStyle(
            color: Colors.black.withOpacity(0.9 * t),
            fontSize: fontWorld,
            fontWeight: FontWeight.w700,
          ),
        );

        // Ancho constante en pantalla (px)
        final maxWidthWorld = 120.0 / (scale * viewerScale);
        textPainter.layout(maxWidth: maxWidthWorld);

        final offset = Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        );

        final bgRect = Rect.fromLTWH(
          offset.dx - padX,
          offset.dy - padY,
          textPainter.width + padX * 2,
          textPainter.height + padY * 2,
        );

        canvas.save();
        canvas.clipPath(path);

        final bgPaint = Paint()..color = Colors.white.withOpacity((0.55 + 0.25 * t));
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, Radius.circular(radius)),
          bgPaint,
        );

        textPainter.paint(canvas, offset);

        canvas.restore();
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => 
    oldDelegate.comarcas != comarcas ||
    oldDelegate.selectedComarcaId != selectedComarcaId ||
    oldDelegate.comarcaPaths != comarcaPaths ||
    oldDelegate.viewerScale != viewerScale;
}