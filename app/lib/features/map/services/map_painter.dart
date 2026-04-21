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

  int? _getNumeroJugador(String username) {
    final jugador = gameState.jugadores[username];
    return jugador?.numeroJugador;
  }

  Color _getMutedPlayerColor(String username) {
    if (username.isEmpty) return AppTheme.mapLandNeutral;

    final numeroJugador = _getNumeroJugador(username);
    if (numeroJugador == null) return AppTheme.mapLandNeutral;

    return ColorUtils.getPlayerMutedColor(numeroJugador);
  }

  bool _esMismoJugador(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a.toLowerCase() == b.toLowerCase();
  }

  bool _esMiTurnoLocal() {
    return _esMismoJugador(gameState.turnoDe, localPlayerId);
  }

  bool _esTerritorioMio(String ownerId) {
    return _esMismoJugador(ownerId, localPlayerId);
  }

  int _tropasReservaJugadorActivo() {
    if (gameState.turnoDe.isEmpty) return 0;
    return gameState.jugadores[gameState.turnoDe]?.tropasReserva ?? 0;
  }

  bool _tieneAdyacenteEnemigo(Comarca comarca) {
    final territoryData = gameState.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';
    if (ownerId.isEmpty) return false;

    for (final adyacenteId in comarca.adjacentTo) {
      final adyacente = gameState.mapa[adyacenteId];
      final ownerAdyacente = adyacente?.ownerId ?? '';
      if (ownerAdyacente.isEmpty) continue;

      if (!_esMismoJugador(ownerAdyacente, ownerId)) {
        return true;
      }
    }

    return false;
  }

  bool _tieneAdyacenteAliado(Comarca comarca) {
    final territoryData = gameState.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';
    if (ownerId.isEmpty) return false;

    for (final adyacenteId in comarca.adjacentTo) {
      final adyacente = gameState.mapa[adyacenteId];
      final ownerAdyacente = adyacente?.ownerId ?? '';
      if (ownerAdyacente.isEmpty) continue;

      if (_esMismoJugador(ownerAdyacente, ownerId)) {
        return true;
      }
    }

    return false;
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
    for (final bridge in MapBridges.data) {
      final path = _buildPuentePath(bridge);
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;

      final metric = metrics.first;
      final length = metric.length;

      

      final plankPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.0 / scale
        ..color = const Color(0xEFFFFFFF);

      final endCirclePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xEFFFFFFF);

      final endCircleShadowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withOpacity(0.08);

      final startTangent = metric.getTangentForOffset(0);
      final endTangent = metric.getTangentForOffset(length);

      if (startTangent == null || endTangent == null) continue;

      final double endRadius = 3.0 / scale;
      final double shadowOffset = 1.5 / scale;

      // Círculos de los extremos
      canvas.drawCircle(
        startTangent.position.translate(shadowOffset, shadowOffset),
        endRadius,
        endCircleShadowPaint,
      );
      canvas.drawCircle(
        endTangent.position.translate(shadowOffset, shadowOffset),
        endRadius,
        endCircleShadowPaint,
      );

      canvas.drawCircle(startTangent.position, endRadius, endCirclePaint);
      canvas.drawCircle(endTangent.position, endRadius, endCirclePaint);

      // Tablones centrales por porcentaje del camino
      final double p1Start = length * 0.21;
      final double p1End = length * 0.31;

      final double p2Start = length * 0.44;
      final double p2End = length * 0.55;

      final double p3Start = length * 0.69;
      final double p3End = length * 0.79;

      final segments = <List<double>>[
        [p1Start, p1End],
        [p2Start, p2End],
        [p3Start, p3End],
      ];

      for (final seg in segments) {
        final start = seg[0].clamp(0.0, length);
        final end = seg[1].clamp(0.0, length);

        if (end <= start) continue;

        final segment = metric.extractPath(start, end);
        canvas.drawPath(segment, plankPaint);
      }
    }
  }

  Offset _getCentroComarca(Path path) {
    return path.getBounds().center;
  }

  void _paintFichaTropas(
    Canvas canvas,
    Offset center,
    String tropas,
    Color fillColor,
    double scale,
    double viewerScale,
  ) {
    final zoomComp = 1.0 + ((viewerScale - 1.0) * 0.55);
    final effectiveZoom = zoomComp.clamp(1.0, 2.4);

    final radioFicha = 10.0 / (scale * effectiveZoom);
    final borderWidth = 1.8 / (scale * effectiveZoom);
    final shadowOffset = 2.0 / (scale * effectiveZoom);

    

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 / scale);
    
    final fillPaint = Paint()..color = fillColor;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = const Color(0xFFFFC93A); 

    canvas.drawCircle(
      center.translate(0, shadowOffset),
      radioFicha,
      shadowPaint,
    );
  
    canvas.drawCircle(center, radioFicha, fillPaint);
    canvas.drawCircle(center, radioFicha, borderPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: tropas,
      style: TextStyle(
        color: Colors.white,
        fontSize: 11.0 / (scale * effectiveZoom),
        fontWeight: FontWeight.w900,
      ),
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _paintComarcaName(
    Canvas canvas,
    Offset center,
    String name,
    double textScale,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    );
  
    textPainter.text = TextSpan(
      text: name.toUpperCase(),
      style: TextStyle(
        color: const Color(0xFFF2F4F8),
        fontSize: 11.5 / textScale,
        fontWeight: FontWeight.w900,
        height: 0.9,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.95),
            offset: Offset(1.2 / textScale, 1.2 / textScale),
            blurRadius: 0.5,
          ),
          Shadow(
            color: Colors.black.withOpacity(0.75),
            offset: Offset(-0.8 / textScale, 0),
          ),
          Shadow(
            color: Colors.black.withOpacity(0.75),
            offset: Offset(0.8 / textScale, 0),
          ),
          Shadow(
            color: Colors.black.withOpacity(0.75),
            offset: Offset(0, -0.8 / textScale),
          ),
          Shadow(
            color: Colors.black.withOpacity(0.75),
            offset: Offset(0, 0.8 / textScale),
          ),
        ],
      ),
    );
  
    textPainter.layout(maxWidth: 110.0 / textScale);
  
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
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

    //final oceanPaint = Paint()..color = AppTheme.mapOcean;
    //canvas.drawRect(Offset.zero & size, oceanPaint);

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

    _paintPuentes(canvas, scale);

    // 3. PINTADO DE TROPAS
    for (final comarca in comarcas) {
      final path = comarcaPaths[comarca.id];
      if (path == null) continue;

      final bounds = path.getBounds();
      if (bounds.width < 20 || bounds.height < 14) continue;

      final territoryData = gameState.mapa[comarca.id];
      final tropas = territoryData != null ? territoryData.units.toString() : '0';
      final ownerId = territoryData?.ownerId ?? '';

      final center = _getCentroComarca(path);
      final fichaColor = _getPlayerColor(ownerId);

      _paintFichaTropas(
        canvas,
        center,
        tropas,
        fichaColor,
        scale,
        viewerScale,
      );
    }

    // 4. NOMBRES SOLO CON ZOOM
    if (viewerScale >= labelMinScale) {
      for (final comarca in comarcas) {
        final path = comarcaPaths[comarca.id];
        if (path == null) continue;

        final bounds = path.getBounds();
        if (bounds.width < 28 || bounds.height < 18) continue;

        final center = _getCentroComarca(path);

        final nameOffset = Offset(
          center.dx,
          center.dy + (9.0 / scale),
        );

        _paintComarcaName(
          canvas,
          nameOffset,
          comarca.name,
          scale * viewerScale,
        );
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
