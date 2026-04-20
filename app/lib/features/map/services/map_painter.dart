import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../config/map_data.dart';
import '../models/territory_model.dart';
import '../../../shared/utils/color_utils.dart';
import '../../game/providers/game_provider.dart';
import '../../../app/theme/app_theme.dart';

class MapPainter extends CustomPainter {
  final List<Region> regions;
  final List<Comarca> comarcas;
  final Map<String, Path> comarcaPaths;

  // Estado completo del juego (Cerebro)
  final GameState gameState;
  final String localPlayerId;

  final double viewerScale;
  final double labelMinScale;
  final double labelFontSizePx;
  final Map<String, Color> coloresPorJugador;

  MapPainter({
    required this.regions,
    required this.comarcas,
    required this.comarcaPaths,
    required this.gameState,
    required this.localPlayerId,
    required this.viewerScale,
    required this.coloresPorJugador,
    this.labelMinScale = 2.0,
    this.labelFontSizePx = 12.0,
  });

  Color _getPlayerColor(String username) {
    if (username.isEmpty) return AppTheme.mapLandNeutral;
    // Usamos el mapa precalculado; si no hay color para el usuario, neutral.
    return coloresPorJugador[username] ?? AppTheme.mapLandNeutral;
  }

  Path? _buildRegionUnionPath(Region region) {
    Path? unionPath;

    for (final comarcaId in region.comarcasIds) {
      final comarcaPath = comarcaPaths[comarcaId];
      if (comarcaPath == null) {
        continue;
      }

      if (unionPath == null) {
        unionPath = Path.from(comarcaPath);
        continue;
      }

      unionPath = Path.combine(ui.PathOperation.union, unionPath, comarcaPath);
    }

    return unionPath;
  }

  int _calcularControlLocalEnRegion(Region region) {
    if (localPlayerId.isEmpty) {
      return 0;
    }

    int controladas = 0;
    for (final comarcaId in region.comarcasIds) {
      final territoryData = gameState.mapa[comarcaId];
      if (territoryData == null) {
        continue;
      }

      if (territoryData.ownerId == localPlayerId) {
        controladas += 1;
      }
    }

    return controladas;
  }

  Path _buildPuentePath(PuenteData bridge) {
    return Path()
      ..moveTo(bridge.from.dx, bridge.from.dy)
      ..quadraticBezierTo(
        bridge.control.dx,
        bridge.control.dy,
        bridge.to.dx,
        bridge.to.dy,
      );
  }

  void _paintPuentes(Canvas canvas, double scale) {
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8.0 / scale
      ..color = Colors.black.withValues(alpha: 0.30);

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5.0 / scale
      ..color = const Color(0xFF5B3923);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.6 / scale
      ..color = const Color(0xFFC7925A);

    for (final bridge in MapBridges.data) {
      final path = _buildPuentePath(bridge);
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, outerPaint);
      canvas.drawPath(path, innerPaint);
    }
  }

  void _paintVistaRegiones(
    Canvas canvas,
    Paint fillPaint,
    Paint baseStroke,
    Paint selectedStroke,
    double scale,
  ) {
    final regionStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppTheme.secondary;

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppTheme.secondary.withValues(alpha: 0.55);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );

    final fontWorld = 12.0 / (scale * viewerScale);
    final radius = 6.0 / (scale * viewerScale);
    final padX = 6.0 / (scale * viewerScale);
    final padY = 4.0 / (scale * viewerScale);

    for (final region in regions) {
      final regionPath = _buildRegionUnionPath(region);
      if (regionPath == null) {
        continue;
      }

      // La vista de regiones siempre usa el color base del tema, no color de jugador.
      fillPaint.color = ColorUtils.getColorRegion(region.id);
      canvas.drawPath(regionPath, fillPaint);
      canvas.drawPath(regionPath, regionStroke);

      final int total = region.comarcasIds.length;
      final int controladas = _calcularControlLocalEnRegion(region);

      int porcentaje = 0;
      if (total > 0) {
        porcentaje = ((controladas * 100) / total).round();
      }

      final textoRegion = '${region.name}\n$controladas/$total - $porcentaje%';
      textPainter.text = TextSpan(
        text: textoRegion,
        style: TextStyle(
          color: AppTheme.text,
          fontSize: fontWorld,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      );
      textPainter.layout(maxWidth: 180.0 / (scale * viewerScale));

      final center = regionPath.getBounds().center;
      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      final textBgRect = Rect.fromLTWH(
        textOffset.dx - padX,
        textOffset.dy - padY,
        textPainter.width + padX * 2,
        textPainter.height + padY * 2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(textBgRect, Radius.circular(radius)),
        Paint()..color = AppTheme.bg.withValues(alpha: 0.58),
      );
      textPainter.paint(canvas, textOffset);
    }

    // Dejamos los bordes internos de comarca para no perder lectura del terreno.
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) {
        continue;
      }

      canvas.drawPath(path, innerStroke);
    }

    // Los resaltados de ataque siguen por encima para no romper la jugabilidad.
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) {
        continue;
      }

      if (comarca.id == gameState.origenSeleccionado) {
        canvas.drawPath(path, selectedStroke);
        continue;
      }

      if (gameState.comarcasResaltadas.contains(comarca.id)) {
        canvas.drawPath(path, selectedStroke);
        continue;
      }

      canvas.drawPath(path, baseStroke);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;

    final baseStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppTheme.secondary;

    final selectedStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = ColorUtils.bordeColor;

    final oceanPaint = Paint()..color = AppTheme.mapOcean;
    canvas.drawRect(Offset.zero & size, oceanPaint);

    // Lógica de Escala y Posicionamiento de la cámara
    final scaleX = size.width / MapPaths.viewBoxWidth;
    final scaleY = size.height / MapPaths.viewBoxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (size.width - (MapPaths.viewBoxWidth * scale)) / 2.0;
    final dy = (size.height - (MapPaths.viewBoxHeight * scale)) / 2.0;
    final extraUp = size.height * 0.05;

    canvas.save();
    canvas.translate(dx, dy - extraUp);
    canvas.scale(scale);
    canvas.translate(-MapPaths.viewBoxX, -MapPaths.viewBoxY);

    _paintPuentes(canvas, scale);

    final bool mostrarVistaRegiones = gameState.vistaRegiones;
    if (mostrarVistaRegiones) {
      _paintVistaRegiones(canvas, fillPaint, baseStroke, selectedStroke, scale);
      canvas.restore();
      return;
    }

    // 1. PINTADO DEL COLOR DE FONDO (Dueños)
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      // Buscamos si esta comarca está en el JSON que nos mandó el backend
      final territoryData = gameState.mapa[comarca.id];

      if (comarca.id == gameState.origenSeleccionado) {
        fillPaint.color = ColorUtils.origenColor;
      } else if (gameState.comarcasResaltadas.contains(comarca.id)) {
        fillPaint.color = ColorUtils.resaltadoColor;
      } else if (territoryData != null && territoryData.ownerId.isNotEmpty) {
        // T48: Si tiene dueño, la pintamos del color del jugador
        fillPaint.color = _getPlayerColor(territoryData.ownerId);
      } else {
        // Si no tiene dueño (inicio del juego), color base de la región
        fillPaint.color = ColorUtils.getColorRegion(comarca.regionId);
      }

      canvas.drawPath(path, fillPaint);
    }

    // 2. PINTADO DE LOS BORDES
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      if (gameState.comarcasResaltadas.contains(comarca.id) ||
          comarca.id == gameState.origenSeleccionado) {
        canvas.drawPath(path, selectedStroke);
      } else {
        canvas.drawPath(path, baseStroke);
      }
    }

    // 3. PINTADO DE ETIQUETAS Y TROPAS (T48)
    if (viewerScale >= labelMinScale) {
      final t = ((viewerScale - labelMinScale) / 0.5).clamp(0.0, 1.0);

      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      );

      final fontWorld = labelFontSizePx / (scale * viewerScale);
      final padX = 6.0 / (scale * viewerScale);
      final padY = 4.0 / (scale * viewerScale);
      final radius = 6.0 / (scale * viewerScale);

      for (final comarca in comarcas) {
        final path = comarcaPaths[comarca.id];
        if (path == null) continue;

        final bounds = path.getBounds();
        if (bounds.width < 25 || bounds.height < 15) continue;

        // T48: Sacamos las tropas del territorio (o mostramos "-" si no hay datos)
        final territoryData = gameState.mapa[comarca.id];
        final tropas = territoryData != null
            ? territoryData.units.toString()
            : "0";

        final center = bounds.center;

        // Componemos el texto: Nombre pequeño arriba, Tropas grandes abajo
        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: "${comarca.name}\n",
              style: TextStyle(
                color: AppTheme.text.withValues(alpha: 0.9 * t),
                fontSize: fontWorld * 0.7, // Nombre un poco más pequeño
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: "🛡️ $tropas",
              style: TextStyle(
                color: AppTheme.text.withValues(alpha: 1.0 * t),
                fontSize: fontWorld * 1.1, // Tropas más grandes
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );

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

        final bgPaint = Paint()
          ..color = AppTheme.bg.withValues(alpha: (0.65 + 0.25 * t));
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
      oldDelegate.gameState != gameState ||
      oldDelegate.localPlayerId != localPlayerId ||
      oldDelegate.viewerScale != viewerScale ||
      oldDelegate.comarcas != comarcas ||
      oldDelegate.regions != regions;
}
