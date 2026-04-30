import 'dart:math' as math;
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
  final GameState? previousGameState; // Para animaciones de transición
  final String localPlayerId;

  final double viewerScale;
  final double labelMinScale;
  final double labelFontSizePx;
  final Map<String, Color> coloresPorJugador;
  final double colorTransitionT;
  final double attackFlowT;

  MapPainter({
    required this.regions,
    required this.comarcas,
    required this.comarcaPaths,
    required this.gameState,
    required this.previousGameState,
    required this.localPlayerId,
    required this.viewerScale,
    required this.coloresPorJugador,
    required this.colorTransitionT,
    required this.attackFlowT,
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
    return a == b;
  }

  bool _esMiTurnoLocal() {
    return _esMismoJugador(gameState.turnoDe, localPlayerId);
  }

  bool _esTerritorioMio(String ownerId) {
    return _esMismoJugador(ownerId, localPlayerId);
  }

  bool _esTerritorioPrioritario(Comarca comarca) {
    if (comarca.id == gameState.origenSeleccionado) return true;
  
    if (gameState.comarcasResaltadas.contains(comarca.id) ||
        gameState.destinoSeleccionado == comarca.id) {
      return true;
    }
  
    return _isTerritorioActivo(comarca);
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

  bool _isTerritorioActivo(Comarca comarca) {
    final territoryData = gameState.mapa[comarca.id];
    if (territoryData == null) return false;

    final ownerId = territoryData.ownerId;
    final tropas = territoryData.units;

    if (ownerId.isEmpty) return false;
    if (!_esTerritorioMio(ownerId)) return false;
    if (!_esMiTurnoLocal()) return false;

    if (comarca.id == gameState.origenSeleccionado) return true;
    if (gameState.comarcasResaltadas.contains(comarca.id)) return true;
    if (gameState.destinoSeleccionado == comarca.id) return true;

    switch (gameState.faseActual.toUpperCase()) {
      case 'REFUERZO':
        return _tropasReservaJugadorActivo() > 0;

      case 'ATAQUE_CONVENCIONAL':
        return tropas > 1 && _tieneAdyacenteEnemigo(comarca);

      case 'FORTIFICACION':
        return tropas > 1 && _tieneAdyacenteAliado(comarca);

      case 'GESTION':
        return true;

      default:
        return false;
    }
  }

  bool _shouldPaintAttackFlows() {
    return gameState.faseActual.toUpperCase() == 'ATAQUE_CONVENCIONAL' &&
        gameState.origenSeleccionado != null &&
        gameState.comarcasResaltadas.isNotEmpty;
  }

  Path _buildAttackLine(Offset from, Offset to) {
    return Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);
  }

  void _paintAnimatedAttackPath(
    Canvas canvas,
    Path path,
    double scale,
  ) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final length = metric.length;
    if (length <= 0) return;

    final double dashLength = 7.0 / scale;
    final double gapLength = 5.0 / scale;
    final double patternLength = dashLength + gapLength;

    final double phase = (1 - attackFlowT) * patternLength;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 4.2 / scale
      ..color = AppTheme.borderGoldVivo.withOpacity(0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 / scale);

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 2.2 / scale
      ..color = AppTheme.borderGoldVivo;

    double distance = -phase;

    while (distance < length) {
      final start = distance < 0 ? 0.0 : distance;
      final end = (distance + dashLength).clamp(0.0, length);

      if (end > start) {
        final segment = metric.extractPath(start, end);
        canvas.drawPath(segment, glowPaint);
        canvas.drawPath(segment, dashPaint);
      }

      distance += patternLength;
    }
  }

  void _paintAttackFlows(Canvas canvas, double scale) {
    final origenId = gameState.origenSeleccionado;
    if (origenId == null) return;

    final origenPath = comarcaPaths[origenId];
    if (origenPath == null) return;

    final origenCenter = _getCentroComarca(origenPath);

    for (final targetId in gameState.comarcasResaltadas) {
      final targetPath = comarcaPaths[targetId];
      if (targetPath == null) continue;

      final targetCenter = _getCentroComarca(targetPath);
      final line = _buildAttackLine(origenCenter, targetCenter);

      _paintAnimatedAttackPath(canvas, line, scale);
    }
  }

  Color _getPlayerColorFromState(String username, GameState state) {
    if (username.isEmpty) return AppTheme.mapLandNeutral;

    final jugador = state.jugadores[username];
    final numeroJugador = jugador?.numeroJugador;
    if (numeroJugador == null) return AppTheme.mapLandNeutral;

    return ColorUtils.getPlayerColor(numeroJugador);
  }

  Color _getMutedPlayerColorFromState(String username, GameState state) {
    if (username.isEmpty) return AppTheme.mapLandNeutral;
  
    final jugador = state.jugadores[username];
    final numeroJugador = jugador?.numeroJugador;
    if (numeroJugador == null) return AppTheme.mapLandNeutral;
  
    return ColorUtils.getPlayerMutedColor(numeroJugador);
  }

  Color _getTerritoryFillColorForState(Comarca comarca, GameState state) {
    final territoryData = state.mapa[comarca.id];

    if (territoryData == null || territoryData.ownerId.isEmpty) {
      return ColorUtils.getColorRegion(comarca.regionId);
    }

    final ownerId = territoryData.ownerId;

    final vivo = _getPlayerColorFromState(ownerId, state);
    final apagado = _getMutedPlayerColorFromState(ownerId, state);

    
    if (comarca.id == state.origenSeleccionado ||
        state.comarcasResaltadas.contains(comarca.id) ||
        state.destinoSeleccionado == comarca.id) {
      return vivo;
    }

    final esMiTurno = state.turnoDe.isNotEmpty && state.turnoDe == localPlayerId;
    final esMio = ownerId == localPlayerId;

    bool esActivo = false;

    if (esMio && esMiTurno) {
      switch (state.faseActual.toUpperCase()) {
        case 'REFUERZO':
          esActivo = (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;
          break;

        case 'ATAQUE_CONVENCIONAL':
          final tropas = territoryData.units;
          if (tropas > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy != ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'FORTIFICACION':
          final tropas = territoryData.units;
          if (tropas > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy == ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'GESTION':
          esActivo = true;
          break;
      }
    }

    return esActivo ? vivo : apagado;
  }

  Color _getTerritoryFillColor(Comarca comarca) {
    final current = _getTerritoryFillColorForState(comarca, gameState);

    if (previousGameState == null) return current;

    final previous = _getTerritoryFillColorForState(comarca, previousGameState!);
    return Color.lerp(previous, current, colorTransitionT) ?? current;
  }

  Color _getTerritoryStrokeColorForState(Comarca comarca, GameState state) {
    final territoryData = state.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';

    final esMiTurno = state.turnoDe.isNotEmpty && state.turnoDe == localPlayerId;
    final esMio = ownerId == localPlayerId;

    bool esActivo = false;

    if (esMio && esMiTurno) {
      if (comarca.id == state.origenSeleccionado ||
          state.comarcasResaltadas.contains(comarca.id) ||
          state.destinoSeleccionado == comarca.id) {
        esActivo = true;
      } else if (territoryData != null) {
        switch (state.faseActual.toUpperCase()) {
          case 'REFUERZO':
            esActivo = (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;
            break;

          case 'ATAQUE_CONVENCIONAL':
            if (territoryData.units > 1) {
              for (final adyacenteId in comarca.adjacentTo) {
                final ady = state.mapa[adyacenteId];
                final ownerAdy = ady?.ownerId ?? '';
                if (ownerAdy.isNotEmpty && ownerAdy != ownerId) {
                  esActivo = true;
                  break;
                }
              }
            }
            break;

          case 'FORTIFICACION':
            if (territoryData.units > 1) {
              for (final adyacenteId in comarca.adjacentTo) {
                final ady = state.mapa[adyacenteId];
                final ownerAdy = ady?.ownerId ?? '';
                if (ownerAdy.isNotEmpty && ownerAdy == ownerId) {
                  esActivo = true;
                  break;
                }
              }
            }
            break;

          case 'GESTION':
            esActivo = true;
            break;
        }
      }
    }

    if (comarca.id == state.origenSeleccionado) {
      return AppTheme.text;
    }

    if (state.comarcasResaltadas.contains(comarca.id) ||
        state.destinoSeleccionado == comarca.id) {
      return ColorUtils.bordeColor;
    }

    if (esActivo) {
      return AppTheme.borderGoldVivo;
    }

    return AppTheme.borderBronze;
  }

  int _getBorderPriorityForState(Comarca comarca, GameState state) {
    if (comarca.id == state.origenSeleccionado) return 3;

    if (state.comarcasResaltadas.contains(comarca.id) ||
        state.destinoSeleccionado == comarca.id) {
      return 2;
    }

    final territoryData = state.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';

    final esMiTurno = state.turnoDe.isNotEmpty && state.turnoDe == localPlayerId;
    final esMio = ownerId == localPlayerId;

    bool esActivo = false;

    if (esMio && esMiTurno && territoryData != null) {
      switch (state.faseActual.toUpperCase()) {
        case 'REFUERZO':
          esActivo = (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;
          break;

        case 'ATAQUE_CONVENCIONAL':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy != ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'FORTIFICACION':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy == ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'GESTION':
          esActivo = true;
          break;
      }
    }

    return esActivo ? 1 : 0;
  }

  int _getAnimatedBorderPriority(Comarca comarca) {
    final current = _getBorderPriorityForState(comarca, gameState);

    if (previousGameState == null) return current;

    final previous = _getBorderPriorityForState(comarca, previousGameState!);
    return current > previous ? current : previous;
  }

  Color _getTerritoryStrokeColor(Comarca comarca) {
    final current = _getTerritoryStrokeColorForState(comarca, gameState);

    if (previousGameState == null) return current;

    final previous = _getTerritoryStrokeColorForState(comarca, previousGameState!);

    final currentPriority = _getBorderPriorityForState(comarca, gameState);
    final previousPriority = _getBorderPriorityForState(comarca, previousGameState!);

    // Aparece desde cero solo si antes no tenía borde.
    if (previousPriority == 0 && currentPriority > 0) {
      final from = current.withAlpha(0);
      return Color.lerp(from, current, colorTransitionT) ?? current;
    }

    // Desaparece del todo solo si ya no tiene borde.
    if (currentPriority == 0 && previousPriority > 0) {
      final to = previous.withAlpha(0);
      return Color.lerp(previous, to, colorTransitionT) ?? current;
    }

    // En cualquier otro caso, transición normal entre colores.
    return Color.lerp(previous, current, colorTransitionT) ?? current;
  }

  double _getTerritoryStrokeWidthForState(Comarca comarca, GameState state) {
    if (comarca.id == state.origenSeleccionado) return 3.0;

    if (state.comarcasResaltadas.contains(comarca.id) ||
        state.destinoSeleccionado == comarca.id) {
      return 3.0;
    }

    final territoryData = state.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';

    final esMiTurno = state.turnoDe.isNotEmpty && state.turnoDe == localPlayerId;
    final esMio = ownerId == localPlayerId;

    bool esActivo = false;

    if (esMio && esMiTurno && territoryData != null) {
      switch (state.faseActual.toUpperCase()) {
        case 'REFUERZO':
          esActivo = (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;
          break;

        case 'ATAQUE_CONVENCIONAL':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy != ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'FORTIFICACION':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy == ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'GESTION':
          esActivo = true;
          break;
      }
    }

    return esActivo ? 3.0 : 1.0;
  }

  double _getTerritoryStrokeWidthAnimated(Comarca comarca) {
    final current = _getTerritoryStrokeWidthForState(comarca, gameState);

    if (previousGameState == null) return current;

    final previous = _getTerritoryStrokeWidthForState(comarca, previousGameState!);

    final currentPriority = _getBorderPriorityForState(comarca, gameState);
    final previousPriority = _getBorderPriorityForState(comarca, previousGameState!);

    

    // Aparece desde cero solo si antes no había borde.
    if (previousPriority == 0 && currentPriority > 0) {
      return ui.lerpDouble(0.0, current, colorTransitionT) ?? current;
    }

    // Desaparece del todo solo si deja de haber borde.
    if (currentPriority == 0 && previousPriority > 0) {
      return ui.lerpDouble(previous, 0.0, colorTransitionT) ?? current;
    }

    // En cualquier otro caso, transición normal.
    return ui.lerpDouble(previous, current, colorTransitionT) ?? current;
  }

  double _getTerritoryStrokeWidth(Comarca comarca) {
    if (comarca.id == gameState.origenSeleccionado) return 3.0;

    if (gameState.comarcasResaltadas.contains(comarca.id) ||
        gameState.destinoSeleccionado == comarca.id) {
      return 3.0;
    }

    if (_isTerritorioActivo(comarca)) {
      return 3.0;
    }

    return 1.0;
  }

  Color _getFichaStrokeColorForState(Comarca comarca, GameState state) {
    final territoryData = state.mapa[comarca.id];
    final ownerId = territoryData?.ownerId ?? '';

    final esMiTurno = state.turnoDe.isNotEmpty && state.turnoDe == localPlayerId;
    final esMio = ownerId == localPlayerId;

    bool esActivo = false;

    if (comarca.id == state.origenSeleccionado) {
      return AppTheme.text;
    }

    if (state.comarcasResaltadas.contains(comarca.id) ||
        state.destinoSeleccionado == comarca.id) {
      return AppTheme.borderGoldVivo;
    }

    if (esMio && esMiTurno && territoryData != null) {
      switch (state.faseActual.toUpperCase()) {
        case 'REFUERZO':
          esActivo = (state.jugadores[state.turnoDe]?.tropasReserva ?? 0) > 0;
          break;

        case 'ATAQUE_CONVENCIONAL':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy != ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'FORTIFICACION':
          if (territoryData.units > 1) {
            for (final adyacenteId in comarca.adjacentTo) {
              final ady = state.mapa[adyacenteId];
              final ownerAdy = ady?.ownerId ?? '';
              if (ownerAdy.isNotEmpty && ownerAdy == ownerId) {
                esActivo = true;
                break;
              }
            }
          }
          break;

        case 'GESTION':
          esActivo = true;
          break;
      }
    }

    return esActivo ? AppTheme.borderGoldVivo : AppTheme.borderGold;
  }

  Color _getFichaStrokeColor(Comarca comarca) {
    final current = _getFichaStrokeColorForState(comarca, gameState);

    if (previousGameState == null) return current;

    final previous = _getFichaStrokeColorForState(comarca, previousGameState!);
    return Color.lerp(previous, current, colorTransitionT) ?? current;
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

  // ---------------------------------------------------------------------------
  // Matraz de fondo redondo centrado en [center] con radio [r]
  // ---------------------------------------------------------------------------
  Path _buildProbetaPath(Offset center, double r) {
    final double rBulb = r * 0.95;
    final double neckW = r * 0.22;
    final double rimW  = r * 0.36;   // semiancho del reborde (labios de la botella)
    final double rimH  = r * 0.06;   // grosor del reborde horizontal
    final double cx = center.dx;

    // Tangencia cuello-bulbo
    final double theta = math.asin((neckW / rBulb).clamp(-1.0, 1.0));
    final double joinY = center.dy - rBulb * math.cos(theta);

    // El cuello sube hasta el reborde
    final double rimBot = joinY - (joinY - (center.dy - r * 1.05)) * 0.55;
    final double rimTop = rimBot - rimH;

    // Tapón: trapecio más estrecho en la base, más ancho arriba
    final double plugBotW = neckW * 1.10;   // semiancho base tapón
    final double plugTopW = neckW * 1.50;   // semiancho cima tapón
    final double plugH    = r * 0.28;        // altura del tapón
    final double plugBot  = rimTop;          // el tapón se apoya en el reborde
    final double plugTop  = plugBot - plugH;
    final double cornerR  = plugH * 0.25;   // radio de esquinas superiores del tapón

    final path = Path();

    // ---- Cuerpo de la botella ----
    // Lado derecho: cuello sube desde el bulbo hasta el reborde
    path.moveTo(cx + neckW, joinY);
    path.lineTo(cx + neckW, rimBot);
    // Reborde derecho
    path.lineTo(cx + rimW, rimBot);
    path.lineTo(cx + rimW, rimTop);
    path.lineTo(cx - rimW, rimTop);
    path.lineTo(cx - rimW, rimBot);
    // Cuello izquierdo baja al bulbo
    path.lineTo(cx - neckW, rimBot);
    path.lineTo(cx - neckW, joinY);
    // Arco del bulbo (largeArc rodea el fondo)
    path.arcToPoint(
      Offset(cx + neckW, joinY),
      radius: Radius.circular(rBulb),
      clockwise: false,
      largeArc: true,
    );
    path.close();

    // ---- Tapón (trapecio con esquinas superiores redondeadas) ----
    path.moveTo(cx - plugBotW, plugBot);
    path.lineTo(cx - plugTopW + cornerR, plugTop + cornerR); // lado izq sube
    // Esquina superior izquierda redondeada
    path.arcToPoint(
      Offset(cx - plugTopW + cornerR, plugTop),
      radius: Radius.circular(cornerR),
      clockwise: false,
    );
    path.lineTo(cx + plugTopW - cornerR, plugTop);
    // Esquina superior derecha redondeada
    path.arcToPoint(
      Offset(cx + plugTopW, plugTop + cornerR),
      radius: Radius.circular(cornerR),
      clockwise: true,
    );
    path.lineTo(cx + plugBotW, plugBot);
    path.close();

    return path;
  }

  // ---------------------------------------------------------------------------
  // Engranaje con dientes anchos y chatos centrado en [center] con radio [r]
  // ---------------------------------------------------------------------------
  Path _buildEngranajePath(Offset center, double r) {
    const int dientes = 8;
    final double rInner = r * 0.88;
    final double rOuter = r * 1.02;
    final double sectorAngle = 2 * math.pi / dientes;
    final double halfSector  = sectorAngle / 2;

    final path = Path();

    for (int i = 0; i < dientes; i++) {
      final double base      = sectorAngle * i - math.pi / 2;
      final double valleEnd  = base + halfSector;
      final double dienteEnd = base + sectorAngle;

      final Offset valleS = Offset(
        center.dx + rInner * math.cos(base),
        center.dy + rInner * math.sin(base),
      );
      final Offset valleE = Offset(
        center.dx + rInner * math.cos(valleEnd),
        center.dy + rInner * math.sin(valleEnd),
      );
      final Offset dienteS = Offset(
        center.dx + rOuter * math.cos(valleEnd),
        center.dy + rOuter * math.sin(valleEnd),
      );
      final Offset dienteE = Offset(
        center.dx + rOuter * math.cos(dienteEnd),
        center.dy + rOuter * math.sin(dienteEnd),
      );
      final Offset nextS = Offset(
        center.dx + rInner * math.cos(dienteEnd),
        center.dy + rInner * math.sin(dienteEnd),
      );

      if (i == 0) path.moveTo(valleS.dx, valleS.dy);

      // 1. Arco del valle (rInner)
      path.arcToPoint(valleE, radius: Radius.circular(rInner), clockwise: true);
      // 2. Subida al diente
      path.lineTo(dienteS.dx, dienteS.dy);
      // 3. Arco de la cabeza del diente (rOuter) → ancho y redondeado
      path.arcToPoint(dienteE, radius: Radius.circular(rOuter), clockwise: true);
      // 4. Bajada al valle
      path.lineTo(nextS.dx, nextS.dy);
    }
    path.close();
    return path;
  }

  // ---------------------------------------------------------------------------

  void _paintFichaTropas(
    Canvas canvas,
    Offset center,
    String tropas,
    Color fillColor,
    Color strokeColor,
    Color textColor,
    double scale,
    double viewerScale, {
    String? estadoBloqueo,
  }) {
    final zoomComp = 1.0 + ((viewerScale - 1.0) * 0.55);
    final effectiveZoom = zoomComp.clamp(1.0, 2.4);

    final radioFicha = 10.0 / (scale * effectiveZoom);
    final borderWidth = 1.8 / (scale * effectiveZoom);
    final shadowOffset = 2.0 / (scale * effectiveZoom);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 / scale);

    final fillPaint = Paint()..color = fillColor;

    final double effectiveBorderWidth = estadoBloqueo == 'trabajando'
        ? borderWidth * 0.65
        : borderWidth;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveBorderWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = strokeColor;

    if (estadoBloqueo == 'investigando') {
      // ── PROBETA ──────────────────────────────────────────────────────────────
      final shapePath = _buildProbetaPath(center, radioFicha);
      final shadowPath = _buildProbetaPath(
        center.translate(0, shadowOffset),
        radioFicha,
      );
      canvas.drawPath(shadowPath, shadowPaint);
      canvas.drawPath(shapePath, fillPaint);
      canvas.drawPath(shapePath, borderPaint);
    } else if (estadoBloqueo == 'trabajando') {
      // ── ENGRANAJE ────────────────────────────────────────────────────────────
      final shapePath = _buildEngranajePath(center, radioFicha);
      final shadowPath = _buildEngranajePath(
        center.translate(0, shadowOffset),
        radioFicha,
      );
      canvas.drawPath(shadowPath, shadowPaint);
      canvas.drawPath(shapePath, fillPaint);
      canvas.drawPath(shapePath, borderPaint);
    } else {
      // ── CÍRCULO ESTÁNDAR ─────────────────────────────────────────────────────
      canvas.drawCircle(
        center.translate(0, shadowOffset),
        radioFicha,
        shadowPaint,
      );
      canvas.drawCircle(center, radioFicha, fillPaint);
      canvas.drawCircle(center, radioFicha, borderPaint);
    }

    final strokePainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    strokePainter.text = TextSpan(
      text: tropas,
      style: TextStyle(
        fontSize: 10.8 / (scale * effectiveZoom),
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 / (scale * effectiveZoom)
          ..color = const Color(0xFF1A1A24),
      ),
    );

    strokePainter.layout();

    final fillPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    fillPainter.text = TextSpan(
      text: tropas,
      style: TextStyle(
        color: textColor,
        fontSize: 10.8 / (scale * effectiveZoom),
        fontWeight: FontWeight.w900,
      ),
    );

    fillPainter.layout();

    final paintOffset = Offset(
      center.dx - fillPainter.width / 2,
      center.dy - fillPainter.height / 2,
    );

    strokePainter.paint(canvas, paintOffset);
    fillPainter.paint(canvas, paintOffset);
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

  static const Map<String, Offset> _regionLabelOffsets = {
    'alto_ebro': Offset(-18, -6),
    'campos_serrania': Offset(-32, 10),
    'valles_matarrana': Offset(34, 8),
    'estepas_y_condados': Offset(18, -10),
    'frontera_pirenaica': Offset(0, -12),
    'sierras_del_sur': Offset(0, 10),
  };

  void _paintRegionLabel(
    Canvas canvas,
    Offset center,
    String text,
    double textScale,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    );

    textPainter.text = TextSpan(
      text: text.toUpperCase(),
      style: TextStyle(
        color: const Color(0xFFF2F4F8),
        fontSize: 13.0 / textScale,
        fontWeight: FontWeight.w900,
        height: 1.0,
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

    textPainter.layout(maxWidth: 180.0 / textScale);

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

    final labels = <({Offset center, String text})>[];

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

      final textoRegion = '${region.name}\n$porcentaje% ($controladas/$total)';
      final baseCenter = regionPath.getBounds().center;
      final offset = _regionLabelOffsets[region.id] ?? Offset.zero;
      final center = baseCenter + offset;

      labels.add((center: center, text: textoRegion));
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

    for (final label in labels) {
      _paintRegionLabel(canvas, label.center, label.text, scale * viewerScale);
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
      //final territoryData = gameState.mapa[comarca.id];

      fillPaint.color = _getTerritoryFillColor(comarca);

      canvas.drawPath(path, fillPaint);
    }

    // 2. PINTADO DE LOS BORDES
    for (var priority = 0; priority <= 3; priority++) {
      for (final comarca in comarcas) {
        if (_getAnimatedBorderPriority(comarca) != priority) continue;

        final path = comarcaPaths[comarca.id];
        if (path == null) continue;

        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _getTerritoryStrokeWidthAnimated(comarca)
          ..color = _getTerritoryStrokeColor(comarca);

        canvas.drawPath(path, strokePaint);
      }
    }

    // ANIMACIÓN DE ATAQUE
    if (_shouldPaintAttackFlows()) {
      _paintAttackFlows(canvas, scale);
    }

    // PINTADO DE PUENTES
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
      final estadoBloqueo = territoryData?.estadoBloqueo;

      final center = _getCentroComarca(path);
      final fichaStrokeColor = _getFichaStrokeColor(comarca);

      final Color finalFichaColor = _getPlayerColor(ownerId);
      const Color finalTextColor = Color(0xFFF0F0F5);

      _paintFichaTropas(
        canvas,
        center,
        tropas,
        finalFichaColor,
        fichaStrokeColor,
        finalTextColor,
        scale,
        viewerScale,
        estadoBloqueo: estadoBloqueo,
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
      oldDelegate.colorTransitionT != colorTransitionT ||
      oldDelegate.attackFlowT != attackFlowT ||
      oldDelegate.comarcas != comarcas ||
      oldDelegate.regions != regions;
}
