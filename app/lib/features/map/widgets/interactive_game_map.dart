import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../services/map_loader.dart';
import '../services/map_painter.dart';
import '../models/territory_model.dart';
import '../config/map_data.dart';
import '../../game/providers/game_provider.dart';
import 'panel_control.dart';
import 'package:dio/dio.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import '../../../shared/api/dio_provider.dart';
import '../../../shared/utils/color_utils.dart';
import '../../../app/theme/app_theme.dart';
import 'game_map_fondo.dart';

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

class _InteractiveGameMapState extends ConsumerState<InteractiveGameMap> 
  with TickerProviderStateMixin {
    late final TransformationController _internalController;
    late final AnimationController _colorAnimController;
    late final Animation<double> _colorAnim;

    late final AnimationController _attackFlowController;
    late final Animation<double> _attackFlowAnim;

    GameState? _animFromGameState;
    GameState? _animToGameState;

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

      _colorAnimController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
      );

      _colorAnimController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animFromGameState = _animToGameState;
        }
      });

      _colorAnim = CurvedAnimation(
        parent: _colorAnimController,
        curve: Curves.linear,
      );

      _attackFlowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 950),
      )..repeat();

      _attackFlowAnim = CurvedAnimation(
        parent: _attackFlowController,
        curve: Curves.linear,
      );

      _colorAnimController.value = 1.0;
    }

    @override
    void dispose() {
      _tc.removeListener(_handleTransformChanged);
      if (_ownsController) _internalController.dispose();
      _colorAnimController.dispose();
      _attackFlowController.dispose();
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

    Rect _boardRect(Size viewport) {
      final boardWidth = viewport.width * 0.8;
      final boardHeight = viewport.height * 1.025;

      final left = (viewport.width - boardWidth) / 3.7;
      final top = viewport.height * 0.145;

      return Rect.fromLTWH(left, top, boardWidth, boardHeight);
    }

    Offset _sceneToMap(Offset scenePoint, Size viewport) {
      final board = _boardRect(viewport);

      final scaleX = board.width / MapPaths.viewBoxWidth;
      final scaleY = board.height / MapPaths.viewBoxHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      final dx =
          board.left + (board.width - (MapPaths.viewBoxWidth * scale)) / 2.0;
      final dy =
          board.top +
          (board.height - (MapPaths.viewBoxHeight * scale)) / 2.0 -
          20;

      // ignore: deprecated_member_use
      final m = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(dx, dy)
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

      _animToGameState ??= gameState;
      _animFromGameState ??= gameState;

      if (!identical(_animToGameState, gameState)) {
        _animFromGameState = _animToGameState;
        _animToGameState = gameState;

        _colorAnimController
          ..stop()
          ..forward(from: 0.0);
      }

      final localPlayerId = ref.watch(
        authProvider.select((auth) => auth.user?.username ?? ''),
      );
      // El HUD de tropas se pinta con watch para repintar en cuanto cambie la reserva.
      final tropasHud = ref.watch(
        gameProvider.select((state) {
          if (state.turnoDe.isEmpty) return 0;
          return state.jugadores[state.turnoDe]?.tropasReserva ?? 0;
        }),
      );

      final panAllowed = _currentScale > widget.minScale + _eps;

      return Stack(
        children: [
          // --- CAPA 1: EL MAPA INTERACTIVO ---
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
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
                    child: GameMapBackground(
                      child: Builder(
                        builder: (context) {
                          final boardRect = _boardRect(viewport);
                          return Stack(
                            children: [
                              Positioned.fromRect(
                                rect: boardRect,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) {
                                    final mapPoint = _sceneToMap(
                                      details.localPosition + boardRect.topLeft,
                                      viewport,
                                    );
                                    final hit = _hitTestComarca(mapPoint);

                                    if (hit != null) {
                                      widget.onTapComarca?.call(hit);
                                    }
                                  },
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([_colorAnim, _attackFlowAnim]),
                                    builder: (context, _) {
                                      return RepaintBoundary(
                                        child: CustomPaint(
                                          painter: MapPainter(
                                            regions: widget.gameMap.regions,
                                            comarcas: widget.gameMap.comarcas,
                                            comarcaPaths: widget.gameMap.comarcaPaths,
                                            // 7. PASAMOS EL ESTADO COMPLETO AL PAINTER
                                            gameState: _animToGameState!,
                                            previousGameState: _animFromGameState,
                                            localPlayerId: localPlayerId,
                                            viewerScale: _currentScale,
                                            coloresPorJugador: _buildColoresPorJugador(_animToGameState!),
                                            colorTransitionT: _colorAnim.value,
                                            attackFlowT: _attackFlowAnim.value,
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Boton de capas del mapa. Va encima del HUD para cambiar rapido de vista.
          Positioned(
            left: 12,
            bottom: 110,
            child: SafeArea(
              top: false,
              right: false,
              child: Material(
                color: const Color(0xFF1C1B22),
                shape: const CircleBorder(
                  side: BorderSide(color: AppTheme.borderGold, width: 2.0),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    tooltip: 'Cambiar vista del mapa',
                    constraints: const BoxConstraints(
                      minWidth: 64,
                      minHeight: 64,
                    ),
                    padding: const EdgeInsets.all(8),
                    icon: Image.asset(
                      'assets/icons/map_icon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      // Toggle simple: vista comarcas <-> vista regiones.
                      ref.read(gameProvider.notifier).toggleVistaRegiones();
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- CAPA 2: EL PANEL DE CONTROL FLOTANTE ---
          // Al estar fuera del InteractiveViewer, no le afecta el zoom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PanelControlGuerra(
              tropas: tropasHud,
              faseActual: gameState.faseActual,
              turnoDe: gameState.turnoDe,
              usernamePropio: localPlayerId,
              // Construimos el mapa de colores dinámicamente desde el estado del juego.
              // Usamos una paleta fija por posición — cuando el backend mande el color
              // real de cada jugador, solo hay que cambiar esto.
              coloresPorJugador: _buildColoresPorJugador(gameState),
              onNextPhasePressed: () => _onNextPhasePressed(context),
            ),
          ),
        ],
      );
    }

    // Construye el mapa username->color para el panel lateral.
    // Asigna colores por orden de aparición hasta que el backend nos mande
    // el color real de cada jugador en el estado de la partida.
    Map<String, Color> _buildColoresPorJugador(GameState gameState) {
      return {
        for (final entry in gameState.jugadores.entries)
          entry.key: ColorUtils.getPlayerColor(entry.value.numeroJugador),
      };
    }

    // El backend es la única fuente de verdad para faseActual.
    // Si pasar_fase falla, no tocamos estado local y la UI muestra error.
    void _onNextPhasePressed(BuildContext context) async {
      try {
        await _pasarFase();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No puedes pasar de fase todavía (¿Te faltan tropas por colocar?)',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Future<void> _pasarFase() async {
      final partidaId = ref.read(webSocketProvider).currentPartidaId;

      if (partidaId == null) {
        throw StateError('No hay partida activa para pasar de fase');
      }

      try {
        final dio = ref.read(dioProvider);
        await dio.post('/partidas/$partidaId/pasar_fase');
        ref.read(gameProvider.notifier).reiniciarTemporizador();
        // Si llega aquí, esperamos CAMBIO_FASE por WS. No hay update optimista.
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        debugPrint('⚠️ pasar_fase rechazado por backend (status: $status)');
        throw StateError('No se pudo pasar de fase');
      }
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

      final board = _boardRect(viewportSize);

      double tx = m.storage[12];
      double ty = m.storage[13];

      // Si estamos en zoom mínimo, bloqueado
      if (s <= widget.minScale + _eps) {
        final locked = Matrix4.diagonal3Values(
          widget.minScale,
          widget.minScale,
          1.0,
        );
        _tc.value = locked;

        if ((_currentScale - widget.minScale).abs() > 1e-4) {
          setState(() => _currentScale = widget.minScale);
        }
        return;
      }

      // Rectángulo REAL del mapa dentro del child
      final scaleX = board.width / MapPaths.viewBoxWidth;
      final scaleY = board.height / MapPaths.viewBoxHeight;
      final baseScale = scaleX < scaleY ? scaleX : scaleY;

      final scaledW = MapPaths.viewBoxWidth * baseScale;
      final scaledH = MapPaths.viewBoxHeight * baseScale;

      final dx = board.left + (board.width - scaledW) / 2.0;
      final dy = board.top + (board.height - scaledH) / 2.0;

      final mapLeft = dx;
      final mapTop = dy;
      final mapRight = dx + scaledW;
      final mapBottom = dy + scaledH;

      final mapW = scaledW * s;
      final mapH = scaledH * s;

      // Horizontal
      bool outsideX = false;

      if (mapW <= board.width) {
        tx = board.left + (board.width - mapW) / 2.0 - mapLeft * s;
      } else {
        final minTx = board.right - mapRight * s;
        final maxTx = board.left - mapLeft * s;
        outsideX = _isOutsideBounds(tx, minTx, maxTx);
        tx = _applyResistance(tx, minTx, maxTx);
      }

      bool outsideY = false;

      if (mapH <= board.height) {
        ty = board.top + (board.height - mapH) / 2.0 - mapTop * s;
      } else {
        final minTy = board.bottom - mapBottom * s;
        final maxTy = board.top - mapTop * s;
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
