import 'package:flutter/material.dart';
import '../config/map_data.dart';
import '../models/territory_model.dart';
import '../../../shared/utils/color_utils.dart'; 
import '../../game/providers/game_provider.dart'; 

class MapPainter extends CustomPainter {
  final List<Comarca> comarcas;
  final Map<String, Path> comarcaPaths;
  
  // Estado completo del juego (Cerebro)
  final GameState gameState; 

  final double viewerScale;
  final double labelMinScale;
  final double labelFontSizePx;

  MapPainter({
    required this.comarcas,
    required this.comarcaPaths,
    required this.gameState, 
    required this.viewerScale,
    this.labelMinScale = 2.0,
    this.labelFontSizePx = 12.0,
  });

  // Función interna para asignar siempre el mismo color a un mismo jugador
  Color _getPlayerColor(String username) {
    if (username.isEmpty) return Colors.grey.shade400; // Territorio neutral
    
    final playerColors = [
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
    ];
    // Usamos el hash del nombre para que siempre le toque el mismo color en la partida
    int hash = username.hashCode.abs();
    return playerColors[hash % playerColors.length];
  }

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
        final tropas = territoryData != null ? territoryData.units.toString() : "0";

        final center = bounds.center;

        // Componemos el texto: Nombre pequeño arriba, Tropas grandes abajo
        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: "${comarca.name}\n",
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.9 * t),
                fontSize: fontWorld * 0.7, // Nombre un poco más pequeño
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: "🛡️ $tropas",
              style: TextStyle(
                color: Colors.black.withValues(alpha: 1.0 * t),
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

        final bgPaint = Paint()..color = Colors.white.withValues(alpha: (0.65 + 0.25 * t));
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
      oldDelegate.viewerScale != viewerScale ||
      oldDelegate.comarcas != comarcas;
}