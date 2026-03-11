import 'package:flutter/material.dart';
import '../config/map_data.dart';
import '../models/territory_model.dart';
import '../../../shared/utils/color_utils.dart'; 
import '../../game/providers/game_provider.dart'; 

class MapPainter extends CustomPainter {
  final List<Comarca> comarcas;
  final Map<String, Path> comarcaPaths;
  
  // Ahora usamos el objeto de estado completo en lugar de solo un ID
  final GameState gameState; 

  final double viewerScale;
  final double labelMinScale;
  final double labelFontSizePx;

  MapPainter({
    required this.comarcas,
    required this.comarcaPaths,
    required this.gameState, // Recibimos el estado (origen + resaltadas)
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

    // Pinceles para destacar la lógica de ataque 
    final attackHighlightStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = ColorUtils.resaltadoColor; 

    final selectedStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white;

    // Lógica de Escala 
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

    // PINTADO DE COMARCAS CON LÓGICA DINÁMICA
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      // Decisión de color basada en el estado del juego 
      if (comarca.id == gameState.origenSeleccionado) {
        fillPaint.color = ColorUtils.origenColor; // Comarca atacante
      } else if (gameState.comarcasResaltadas.contains(comarca.id)) {
        fillPaint.color = ColorUtils.resaltadoColor; // Comarcas en rango BFS
      } else {
        fillPaint.color = ColorUtils.getColorRegion(comarca.regionId); // Color normal
      }

      canvas.drawPath(path, fillPaint);
      
    }

    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      // Si la comarca está resaltada, le ponemos un borde un poco más oscuro o marcado
      if (gameState.comarcasResaltadas.contains(comarca.id) || 
          comarca.id == gameState.origenSeleccionado) {
        canvas.drawPath(path, selectedStroke); // El borde blanco que definiste
      } else {
        canvas.drawPath(path, baseStroke); // El borde gris/oscuro normal
      }
    }

// Labels (Etiquetas de las comarcas con ajuste dinámico)
    if (viewerScale >= labelMinScale) {
      // Cálculo del fade-in suave basado en el zoom actual
      final t = ((viewerScale - labelMinScale) / 0.5).clamp(0.0, 1.0);

      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      );

      // Calculamos el tamaño de fuente y padding "mundo" para que en pantalla 
      // siempre se vean del mismo tamaño independientemente del zoom
      final fontWorld = labelFontSizePx / (scale * viewerScale);
      final padX = 6.0 / (scale * viewerScale);
      final padY = 4.0 / (scale * viewerScale);
      final radius = 6.0 / (scale * viewerScale);

      for (final comarca in comarcas) {
        final path = comarcaPaths[comarca.id];
        if (path == null) {
          debugPrint("❌ ERROR: No hay dibujo para el ID: '${comarca.id}'");
          continue;
        }

        final bounds = path.getBounds();
        // Solo dibujamos el texto si la comarca es lo suficientemente grande en pantalla
        if (bounds.width < 25 || bounds.height < 15) continue;

        final center = bounds.center;

        textPainter.text = TextSpan(
          text: comarca.name,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.9 * t),
            fontSize: fontWorld,
            fontWeight: FontWeight.w700,
          ),
        );

        // Limitamos el ancho del texto para que no se salga de la comarca
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
        // ClipPath para que el fondo blanco de la etiqueta no se salga de los bordes de la comarca
        canvas.clipPath(path);

        // Fondo semi-transparente que se vuelve más opaco al hacer zoom
        final bgPaint = Paint()..color = Colors.white.withValues(alpha: (0.55 + 0.25 * t));
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
      oldDelegate.gameState != gameState || // Repintar si cambia la selección o el BFS
      oldDelegate.viewerScale != viewerScale ||
      oldDelegate.comarcas != comarcas;
}