import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/features/game/models/partida_log_model.dart';
import 'package:soberania/features/game/services/tech_catalog_service.dart';
import 'package:soberania/features/game/services/partida_logs_service.dart';
import 'package:soberania/features/game/widgets/partida_logs_panel.dart';
import 'package:soberania/features/game/widgets/reacciones_button.dart';
import 'package:soberania/features/map/services/map_loader.dart';
import 'package:soberania/features/map/widgets/action_panel.dart';
import 'package:soberania/features/map/widgets/interactive_game_map.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';
import 'package:soberania/features/game/widgets/tech_tree_view.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/api/dio_provider.dart';
import '../../../shared/utils/color_utils.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../app/router/app_routes.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/lobby_info_provider.dart';
import '../../map/widgets/gestion_panel.dart';

class BatallaScreen extends ConsumerStatefulWidget {
  const BatallaScreen({super.key, required this.title, this.partidaId = 0});

  final String title;
  final int partidaId;

  @override
  ConsumerState<BatallaScreen> createState() => _BatallaScreenState();
}

class _BatallaScreenState extends ConsumerState<BatallaScreen> {
  late final Future<GameMap> _mapFuture;
  bool _partidaTerminada = false;
  bool _jugadorLocalEliminado = false;
  bool _modoEspectador = false;
  bool _cargandoCatalogoTecnologias = false;
  bool _hayDialogoPopupActivo = false;
  bool _resolviendoResultadoAtaque = false;
  Timer? _reactionBubbleTimer;
  _ReactionBubbleData? _reactionBubble;
  List<TechNodeModel> _techNodes = const <TechNodeModel>[];
  Size _techCanvasSize = const Size(1200, 790);
  String? _techCatalogError;
  // Código de invitación de la partida actual. Se rellena en initState
  // llamando al servidor para cubrir el caso en que el jugador
  // llega desde el menú de pausadas (lobbyInfoProvider vacío).
  String? _codigoPartida;
  String? _comarcaGestionSeleccionada;


  TechCatalogService get _techCatalogService =>
      TechCatalogService(ref.read(dioProvider));

  PartidaLogsService get _partidaLogsService =>
      PartidaLogsService(ref.read(dioProvider));

  int _partidaIdActual() {
    if (widget.partidaId > 0) return widget.partidaId;
    return ref.read(webSocketProvider).currentPartidaId ?? 0;
  }

  int _contarJugadoresVivos(GameState state) {
    final jugadoresConTerritorios = state.mapa.values
        .map((territorio) => territorio.ownerId)
        .where((ownerId) => ownerId.trim().isNotEmpty)
        .toSet();

    return jugadoresConTerritorios.length;
  }

  Future<void> _sincronizarEstadoPartida(int partidaId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/partidas/$partidaId/estado');
    if (response.data is! Map) return;

    final payload = Map<String, dynamic>.from(response.data as Map);
    ref.read(gameProvider.notifier).actualizarDesdeServidor(payload);
  }

  void _onResearchPressed(String habilidadId, int cost) async {
    if (_jugadorLocalEliminado || _modoEspectador) return;

    final partidaId = _partidaIdActual();
    if (partidaId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la partida actual.'),
        ),
      );
      return;
    }

    try {
      await _techCatalogService.buyTechnology(
        partidaId: partidaId,
        habilidadId: habilidadId,
      );

      final jugadorId = ref.read(authProvider).user?.username ?? '';
      if (jugadorId.isNotEmpty) {
        ref
            .read(gameProvider.notifier)
            .marcarTecnologiaComprada(
              jugadorId: jugadorId,
              tecnologiaId: habilidadId,
            );
      }

      await _sincronizarEstadoPartida(partidaId);

      if (!mounted) return;
      final nombreTech = _formatName(habilidadId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1A12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.borderGoldVivo, width: 1),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.science_rounded,
                color: AppTheme.borderGoldVivo,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Investigación completada! Has adquirido $nombreTech.',
                  style: const TextStyle(
                    color: AppTheme.borderGoldVivo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final detalle = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ??
                e.message ??
                'No se pudo comprar la tecnología')
          : (e.message ?? 'No se pudo comprar la tecnología');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1212),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFBF5050), width: 1),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFBF5050),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  detalle,
                  style: const TextStyle(
                    color: Color(0xFFE89090),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatName(String id) {
    return id
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void _cerrarPanelGestion() {
    final comarcaId = _comarcaGestionSeleccionada;
    final miUsuario = ref.read(authProvider).user?.username ?? '';

    if (comarcaId != null && miUsuario.isNotEmpty) {
      ref
          .read(gameProvider.notifier)
          .seleccionarComarca(comarcaId, jugadorLocalId: miUsuario);
    }

    setState(() {
      _comarcaGestionSeleccionada = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _mapFuture = MapLoader.loadMap();
    Future<void>.microtask(_cargarCatalogoTecnologias);
    Future<void>.microtask(_resolverCodigoPartida);
  }

  @override
  void dispose() {
    _reactionBubbleTimer?.cancel();
    super.dispose();
  }

  // Intenta obtener el código de invitación desde el servidor.
  // El lobbyInfoProvider puede estar vacío si el jugador entró
  // desde el menú de partidas pausadas en lugar del flujo normal.
  Future<void> _resolverCodigoPartida() async {
    // Primero intentamos el provider en memoria (flujo normal).
    final codigoEnMemoria = ref.read(lobbyInfoProvider).codigoInvitacion;
    if (codigoEnMemoria != null && codigoEnMemoria.isNotEmpty) {
      if (mounted) setState(() => _codigoPartida = codigoEnMemoria);
      return;
    }

    // Si no hay nada en memoria, preguntamos al servidor.
    try {
      final partida = await ref
          .read(matchmakingServiceProvider)
          .getMiPartidaActiva();
      if (partida != null && partida.codigoInvitacion.isNotEmpty && mounted) {
        if (partida.configTimerSeconds > 0) {
          ref
              .read(lobbyInfoProvider.notifier)
              .setTimerSeconds(partida.configTimerSeconds);
        }
        // Persistimos el código en el provider para que no se pierda
        // si el usuario vuelve a la pantalla sin reiniciar el flujo.
        ref
            .read(lobbyInfoProvider.notifier)
            .rescatarCodigoInvitacion(partida.codigoInvitacion);
        setState(() => _codigoPartida = partida.codigoInvitacion);
      }
    } catch (_) {
      // Si falla, _codigoPartida sigue siendo null y el botón
      // de pausa lo notificará al usuario cuando lo pulse.
    }
  }

  Future<void> _cargarCatalogoTecnologias() async {
    if (_cargandoCatalogoTecnologias) return;
    _cargandoCatalogoTecnologias = true;

    try {
      final partidaId = _partidaIdActual();
      if (partidaId <= 0) {
        if (!mounted) return;
        setState(() {
          _techCatalogError =
              'No se pudo identificar la partida para cargar tecnologías.';
        });
        return;
      }

      final catalog = await _techCatalogService.fetchCatalog(
        partidaId: partidaId,
      );

      if (!mounted) return;
      setState(() {
        _techNodes = catalog.nodes;
        _techCanvasSize = catalog.canvasSize;
        _techCatalogError = catalog.nodes.isEmpty
            ? 'No llegaron tecnologias desde backend. Revisa /partidas/{partida_id}/tecnologias y el payload (ramas/arbol).'
            : null;
      });
    } on DioException catch (e) {
      debugPrint(
        'No se pudo cargar catalogo de tecnologias: ${e.response?.statusCode} ${e.message}',
      );

      if (!mounted) return;
      setState(() {
        _techCatalogError =
            'Error cargando catalogo (${e.response?.statusCode ?? 'sin codigo'}).';
      });
    } catch (e) {
      debugPrint('Error parseando catalogo de tecnologias: $e');

      if (!mounted) return;
      setState(() {
        _techCatalogError = 'Error parseando catalogo: $e';
      });
    } finally {
      _cargandoCatalogoTecnologias = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (previous, next) {
      final miUsuario = ref.read(authProvider).user?.username;
      if (miUsuario == null || miUsuario.isEmpty) return;

      if (_jugadorLocalEliminado || _modoEspectador) return;

      final faseActual = next.faseActual.toLowerCase();
      final faseAnterior = previous?.faseActual.toLowerCase();

      if (faseActual != 'gestion' && _comarcaGestionSeleccionada != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _cerrarPanelGestion();
        });
      }

      final esMiTurno = next.turnoDe == miUsuario;
      final antesEraMiTurno = previous?.turnoDe == miUsuario;

      // --- Popup de refuerzo — solo al entrar en fase refuerzo de nuestro turno ---
      final entraEnRefuerzo =
          faseActual == 'refuerzo' &&
          esMiTurno &&
          !(faseAnterior == 'refuerzo' && antesEraMiTurno);

      if (entraEnRefuerzo) {
        final tropasRecibidas = next.tropasRecibidasTurno;
        final investigacion = next.investigacionCompletada.trim();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mostrarPopup(
            titulo: '🎖️ Inicio de turno',
            mensaje:
                'Refuerzos recibidos: +$tropasRecibidas tropas'
                '${investigacion.isNotEmpty ? '\n🔬 Lab: $investigacion' : ''}',
          );
        });
      }

      // --- Popup de monedas — solo al entrar en fase gestión de nuestro turno ---
      final entraEnGestion =
          faseActual == 'gestion' &&
          esMiTurno &&
          !(faseAnterior == 'gestion' && antesEraMiTurno);

      if (entraEnGestion) {
        final monedasGanadas = next.monedasGanadasUltimoTurno;
        if (monedasGanadas > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mostrarPopup(
              titulo: '💰 Producción',
              mensaje: 'Tu mina ha producido +$monedasGanadas monedas.',
            );
          });
        }
      }
    });

    ref.listen<WebSocketState>(webSocketProvider, (previous, next) {
      final prevVersion = previous?.versionEventoSistema ?? 0;
      if (next.versionEventoSistema <= prevVersion) return;

      final tipo = next.tipoEventoSistema;
      if (tipo == null) return;

      final miUsuario = ref.read(authProvider).user?.username;
      final payload = next.payloadEventoSistema ?? const <String, dynamic>{};

      // SOLICITUD_PAUSA: alguien pidió pausar — mostramos el diálogo de voto
      // a todos menos al solicitante, que ya está esperando.
      if (tipo == 'SOLICITUD_PAUSA') {
        final solicitante =
            (payload['solicitante'] ?? next.jugadorEventoSistema)?.toString() ??
            '';

        if (miUsuario != null &&
            miUsuario.isNotEmpty &&
            solicitante == miUsuario) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final voto = await _mostrarPopupDecision(
            titulo: 'Pausar partida',
            mensaje:
                '${solicitante.isNotEmpty ? solicitante : 'Un jugador'} propone pausar. ¿Pausar partida?',
          );
          if (!mounted || voto == null) return;

          final codigo = _codigoPartida;
          if (codigo == null || codigo.isEmpty) {
            unawaited(
              _mostrarPopup(
                titulo: 'Error al votar',
                mensaje: 'No se encontró el código de la partida.',
              ),
            );
            return;
          }

          try {
            await ref
                .read(matchmakingServiceProvider)
                .votarPausa(codigo, aFavor: voto == true);
          } on DioException catch (e) {
            if (!mounted) return;
            final detalle = e.response?.data is Map<String, dynamic>
                ? (e.response?.data['detail']?.toString() ??
                      e.message ??
                      'No se pudo registrar tu voto')
                : (e.message ?? 'No se pudo registrar tu voto');
            unawaited(
              _mostrarPopup(titulo: 'Error al votar pausa', mensaje: detalle),
            );
          }
        });
        return;
      }

      if (tipo == 'PAUSA_RECHAZADA') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_hayDialogoPopupActivo) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          unawaited(
            _mostrarPopup(
              titulo: 'Pausa rechazada',
              mensaje: 'La partida continúa.',
            ),
          );
        });
        return;
      }

      if (tipo == 'PARTIDA_PAUSADA') {
        _partidaTerminada = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_hayDialogoPopupActivo) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          unawaited(
            _mostrarPopup(
              titulo: 'Partida pausada',
              mensaje: 'La pausa fue aprobada. Volverás al menú principal.',
              alAceptar: () {
                if (mounted) context.go('/home');
              },
            ),
          );
        });
        return;
      }

      // PARTIDA_REANUDADA: el host reanudó desde el lobby — volvemos a batallar.
      if (tipo == 'PARTIDA_REANUDADA') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_hayDialogoPopupActivo) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          // La fase ya la actualizó el websocket_provider; navegamos directamente.
          context.go(AppRoutes.batalla);
        });
        return;
      }

      if (tipo == 'JUGADOR_ELIMINADO') {
        final jugador = next.jugadorEventoSistema ?? 'Desconocido';
        final esYo = miUsuario != null && jugador == miUsuario;

        if (esYo) {
          _jugadorLocalEliminado = true;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;

            final partidaId = _partidaIdActual();

            if (partidaId > 0) {
              try {
                await _sincronizarEstadoPartida(partidaId);
              } catch (e) {
                debugPrint('Error sincronizando estado tras eliminación: $e');
              }
            }

            if (!mounted) return;

            final gameStateActual = ref.read(gameProvider);
            final jugadoresVivos = _contarJugadoresVivos(gameStateActual);
            final puedeEspectar = jugadoresVivos > 1;

            await _mostrarDialogoEliminado(
              puedeEspectar: puedeEspectar,
            );
          });
          
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mostrarPopup(
            titulo: 'Jugador eliminado',
            mensaje: '$jugador ha sido eliminado de la partida.',
          );
        });

        return;
      }

      if (tipo == 'REACCION' || tipo == 'CHAT' || tipo == 'MENSAJE_CHAT') {
        final payload = next.payloadEventoSistema ?? const <String, dynamic>{};
        final jugador =
            (payload['jugador'] ??
                    payload['usuario'] ??
                    payload['emisor'] ??
                    payload['username'] ??
                    next.jugadorEventoSistema)
                ?.toString();
        final tipoReaccion =
            (payload['tipo'] ??
                    payload['tipo_mensaje'] ??
                    payload['clase'] ??
                    (payload['archivo'] != null ? 'reaccion' : null))
                ?.toString() ??
            '';
        final contenido =
            (payload['contenido'] ??
                    payload['archivo'] ??
                    payload['reaccion'] ??
                    payload['texto'] ??
                    payload['mensaje'])
                ?.toString() ??
            '';

        if (contenido.trim().isEmpty) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mostrarNotificacionReaccion(
            jugador: jugador ?? 'Jugador',
            tipo: tipoReaccion,
            contenido: contenido,
          );
        });
        return;
      }

      if (tipo == 'PARTIDA_FINALIZADA' || tipo == 'FIN_PARTIDA') {
        _partidaTerminada = true;
        final ganador = next.ganadorEventoSistema;
        final esVictoria =
            miUsuario != null && ganador != null && ganador == miUsuario;

        final titulo = esVictoria ? '¡Victoria!' : 'Fin de la partida';
        final mensaje =
            next.mensajeEventoSistema ??
            (ganador != null
                ? 'Ganador: $ganador. Regresarás al lobby.'
                : 'La partida ha terminado. Regresarás al lobby.');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarDialogoSistemaYSalir(titulo, mensaje);
        });
      }
    });

    ref.listen<GameState>(gameProvider, (previous, next) {
      // Si ya terminó la partida, no lanzamos popups de combate.
      if (_partidaTerminada || _jugadorLocalEliminado || _modoEspectador) return;

      final prevVersion = previous?.versionResultadoAtaque ?? 0;
      final hayNuevoResultado =
          next.ultimoResultadoAtaque != null &&
          next.versionResultadoAtaque > prevVersion;

      if (!hayNuevoResultado || _resolviendoResultadoAtaque) return;

      final resultado = next.ultimoResultadoAtaque!;
      _resolviendoResultadoAtaque = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _resolviendoResultadoAtaque = false;
          return;
        }

        try {
          await _mostrarPopup(
            titulo: 'Ataque en ${_formatName(resultado.destino)}',
            mensaje:
                'Has perdido ${resultado.bajasAtacante} tropa(s).\n'
                'El enemigo perdió ${resultado.bajasDefensor} tropa(s).\n'
                '${resultado.victoria ? '¡Territorio conquistado!' : 'El territorio resiste.'}',
          );

          if (resultado.victoria && mounted) {
            await _mostrarDialogoMoverConquista(
              territorioConquistado: resultado.destino,
              territorioOrigen: resultado.origen,
              tropasDisponibles: resultado.tropasRestantesOrigen,
            );
          }
        } finally {
          ref.read(gameProvider.notifier).limpiarResultadoAtaque();
          _resolviendoResultadoAtaque = false;
        }
      });
    });

    final miUsuarioHud = ref.watch(
      authProvider.select((auth) => auth.user?.username ?? ''),
    );
    final estadoHud = ref.watch(gameProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<GameMap>(
        future: _mapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No hay mapa.'));
          }

          return Stack(
            children: [
              InteractiveGameMap(
                gameMap: snapshot.data!,
                onTapComarca: (c) {
                  if (_jugadorLocalEliminado || _modoEspectador) return;

                  final estadoActual = ref.read(gameProvider);
                  final miUsuario = ref.read(authProvider).user?.username ?? '';
                  final faseActual = estadoActual.faseActual.toLowerCase();
                  final esMiTurno = estadoActual.turnoDe == miUsuario;

                  if (faseActual == 'gestion') {
                    final ownerId = estadoActual.mapa[c.id]?.ownerId ?? '';
                    final esComarcaPropia =
                        miUsuario.isNotEmpty && ownerId == miUsuario;

                    if (!esComarcaPropia || !esMiTurno) return;

                    final yaEstabaAbierta = _comarcaGestionSeleccionada == c.id;

                    ref
                        .read(gameProvider.notifier)
                        .seleccionarComarca(c.id, jugadorLocalId: miUsuario);

                    setState(() {
                      _comarcaGestionSeleccionada = yaEstabaAbierta
                          ? null
                          : c.id;
                    });

                    return;
                  }

                  ref
                      .read(gameProvider.notifier)
                      .seleccionarComarca(
                        c.id,
                        jugadorLocalId: miUsuario,
                        vecinosDelNodoTocado: c.adjacentTo,
                      );
                },
                minScale: 1.0,
                maxScale: 5.0,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.goldMain,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldDark.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            blurStyle: BlurStyle.inner,
                          ),
                          BoxShadow(
                            color: AppTheme.panelShadow.withValues(alpha: 0.7),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const ReaccionesButton(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.goldMain,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldDark.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            blurStyle: BlurStyle.inner,
                          ),
                          BoxShadow(
                            color: AppTheme.panelShadow.withValues(alpha: 0.7),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Logs de partida',
                        onPressed: _mostrarLogsPartidaModal,
                        icon: const Icon(
                          Icons.feed_outlined,
                          color: AppTheme.goldMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                width: 190,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PlayerInfoPanel(
                    gameState: estadoHud,
                    jugadorLocalId: miUsuarioHud,
                    panelHeight: MediaQuery.of(context).size.height * 0.60,
                  ),
                ),
              ),
              if (_reactionBubble != null)
                Positioned(
                  left: 215,
                  top: _reactionBubbleTop(
                    context: context,
                    gameState: estadoHud,
                    jugador: _reactionBubble!.jugador,
                  ) - 12,
                  child: _ReactionBubbleView(
                    data: _reactionBubble!,
                    imageUrlBuilder: _reactionImageUrl,
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, top: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252530).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.2,
                      ),
                    ),
                    child: IconButton(
                      tooltip: (_jugadorLocalEliminado || _modoEspectador)
                          ? 'Salir de la partida'
                          : 'Solicitar pausa',
                      icon: Icon(
                        (_jugadorLocalEliminado || _modoEspectador)
                            ? Icons.exit_to_app_rounded
                            : Icons.pause_circle_outline_rounded,
                        color: AppTheme.borderGold,
                      ),
                      onPressed: (_jugadorLocalEliminado || _modoEspectador)
                          ? () async {
                              final salir = await _mostrarPopupDecision(
                                titulo: 'Salir de la partida',
                                mensaje: '¿Quieres dejar de espectar y volver al menú principal?',
                              );

                              if (!mounted || salir != true) return;

                              context.go('/home');
                            }
                          : () async {
                              final confirmar = await _mostrarPopupDecision(
                                titulo: '¿Solicitar pausa?',
                                mensaje:
                                    'Se pedirá al resto de jugadores que voten para pausar la partida.',
                              );
                              if (!mounted || confirmar != true) return;

                              final codigo = _codigoPartida;
                              if (codigo == null || codigo.isEmpty) {
                                unawaited(
                                  _mostrarPopup(
                                    titulo: 'Error',
                                    mensaje: 'No se encontró el código de la partida.',
                                  ),
                                );
                                return;
                              }

                              unawaited(
                                _mostrarPopup(
                                  titulo: 'Votación en curso',
                                  mensaje: 'Esperando al resto de jugadores...',
                                ),
                              );

                              try {
                                await ref
                                    .read(matchmakingServiceProvider)
                                    .solicitarPausa(codigo);

                                await ref
                                    .read(matchmakingServiceProvider)
                                    .votarPausa(codigo, aFavor: true);
                              } on DioException catch (e) {
                                if (!mounted) return;

                                if (_hayDialogoPopupActivo) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }

                                final detalle = e.response?.data is Map<String, dynamic>
                                    ? (e.response?.data['detail']?.toString() ??
                                          e.message ??
                                          'No se pudo solicitar la pausa')
                                    : (e.message ?? 'No se pudo solicitar la pausa');

                                unawaited(
                                  _mostrarPopup(
                                    titulo: 'Error al pausar',
                                    mensaje: detalle,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ),
              ),
              if (_modoEspectador)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252530).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.borderGold.withOpacity(0.85),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            color: AppTheme.borderGold,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Modo espectador',
                            style: TextStyle(
                              color: AppTheme.borderGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 26,
                child: SafeArea(
                  top: false,
                  left: false,
                  minimum: const EdgeInsets.only(right: 4, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          ref
                              .read(gameProvider.notifier)
                              .toggleVistaRegiones();
                        },
                        child: Image.asset(
                          'assets/icons/map_icon2.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _mostrarArbolTecnologicoModal(context),
                        child: Image.asset(
                          'assets/icons/tree_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_jugadorLocalEliminado && !_modoEspectador)
                ActionPanel(techNodes: _techNodes),
              
              if (!_jugadorLocalEliminado && !_modoEspectador)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: _comarcaGestionSeleccionada != null ? 12 : -360,
                  top: MediaQuery.of(context).size.height * 0.12,
                  width: 360,
                  child: IgnorePointer(
                    ignoring: _comarcaGestionSeleccionada == null,
                    child: GestionPanel(
                      comarcaId: _comarcaGestionSeleccionada ?? '',
                      partidaId: widget.partidaId,
                      onClose: _cerrarPanelGestion,
                      techNodes: _techNodes,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _colorJugador(String actor) {
    final trimmed = actor.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'sistema') {
      return AppTheme.textSecondary;
    }

    final state = ref.read(gameProvider);
    final jugador = state.jugadores[trimmed];
    final numero = jugador?.numeroJugador;
    if (numero == null) return AppTheme.text;
    return ColorUtils.getPlayerColor(numero);
  }

  Future<void> _mostrarLogsPartidaModal() async {
    final partidaId = _partidaIdActual();
    if (partidaId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la partida para cargar logs.'),
        ),
      );
      return;
    }

    List<PartidaLogModel> logs = const <PartidaLogModel>[];
    bool cargando = true;
    String? error;

    Future<void> cargar(StateSetter setModalState) async {
      setModalState(() {
        cargando = true;
        error = null;
      });

      try {
        final fetched = await _partidaLogsService.fetchLogs(
          partidaId: partidaId,
        );
        setModalState(() {
          logs = fetched;
          cargando = false;
        });
      } on DioException catch (e) {
        final detalle = e.response?.data is Map<String, dynamic>
            ? (e.response?.data['detail']?.toString() ??
                  e.message ??
                  'No se pudieron cargar logs')
            : (e.message ?? 'No se pudieron cargar logs');

        setModalState(() {
          error = detalle;
          cargando = false;
        });
      } catch (e) {
        setModalState(() {
          error = 'Error al cargar logs: $e';
          cargando = false;
        });
      }
    }

    try {
      logs = await _partidaLogsService.fetchLogs(partidaId: partidaId);
      cargando = false;
    } on DioException catch (e) {
      final detalle = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ??
                e.message ??
                'No se pudieron cargar logs')
          : (e.message ?? 'No se pudieron cargar logs');
      error = detalle;
      cargando = false;
    } catch (e) {
      error = 'Error al cargar logs: $e';
      cargando = false;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final maxHeight = MediaQuery.of(sheetContext).size.height * 0.86;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Logs de la partida',
                              style: TextStyle(
                                color: AppTheme.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Recargar',
                            onPressed: () => cargar(setModalState),
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderGold),
                    Expanded(
                      child: PartidaLogsPanel(
                        logs: logs,
                        isLoading: cargando,
                        error: error,
                        onRetry: () => cargar(setModalState),
                        colorResolver: _colorJugador,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBattleDialog({
    required BuildContext context,
    required Widget child,
    double maxWidth = 360,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screenHeight * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  ButtonStyle _battlePrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3A2A16),
      foregroundColor: AppTheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.primary.withValues(alpha: 0.75),
          width: 1.1,
        ),
      ),
    );
  }

  ButtonStyle _battleSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primary,
      side: BorderSide(
        color: AppTheme.primary.withValues(alpha: 0.55),
        width: 1.1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _mostrarPopup({
    required String titulo,
    required String mensaje,
    bool barrierDismissible = false,
    VoidCallback? alAceptar,
  }) async {
    if (!mounted) return;
    _hayDialogoPopupActivo = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return _buildBattleDialog(
          context: context,
          maxWidth: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    alAceptar?.call();
                  },
                  style: _battlePrimaryButtonStyle(),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    _hayDialogoPopupActivo = false;
  }

  String _reactionImageUrl(String fileName) {
    final normalized = fileName.trim();
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://')) {
      return normalized;
    }

    if (normalized.startsWith('/')) {
      return 'https://soberania.dev$normalized';
    }

    return 'https://soberania.dev/static/reacciones/$normalized';
  }

  void _mostrarNotificacionReaccion({
    required String jugador,
    required String tipo,
    required String contenido,
  }) {
    if (!mounted) return;

    _reactionBubbleTimer?.cancel();
    setState(() {
      _reactionBubble = _ReactionBubbleData(
        jugador: jugador,
        tipo: tipo,
        contenido: contenido,
      );
    });

    _reactionBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _reactionBubble = null);
    });
  }

  double _reactionBubbleTop({
    required BuildContext context,
    required GameState gameState,
    required String jugador,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.60;
    final jugadores = gameState.jugadores.entries.toList(growable: false)
      ..sort((a, b) => a.value.numeroJugador.compareTo(b.value.numeroJugador));
    final index = jugadores.indexWhere((entry) => entry.key == jugador);
    final safeIndex = index < 0 ? 0 : index;
    final panelTop = (screenHeight - panelHeight) / 2;
    return panelTop + 18 + safeIndex * 72;
  }

  Future<bool?> _mostrarPopupDecision({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return null;
    _hayDialogoPopupActivo = true;

    final respuesta = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _buildBattleDialog(
          context: context,
          maxWidth: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: _battlePrimaryButtonStyle(),
                  child: const Text(
                    'Sí',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: _battleSecondaryButtonStyle(),
                  child: const Text(
                    'No',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    _hayDialogoPopupActivo = false;
    return respuesta;
  }

  Future<void> _mostrarDialogoSistemaYSalir(
    String titulo,
    String mensaje,
  ) async {
    await _mostrarPopup(
      titulo: titulo,
      mensaje: mensaje,
      barrierDismissible: false,
      alAceptar: () {
        if (mounted) context.go('/lobby');
      },
    );
  }

  Future<void> _mostrarDialogoEliminado({
    required bool puedeEspectar,
  }) async {
    if (!mounted) return;

    _hayDialogoPopupActivo = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: _buildBattleDialog(
            context: context,
            maxWidth: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HAS SIDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE84A4A),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ELIMINADO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE84A4A),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Tus legiones han caído y tus tierras han sido reclamadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu soberanía termina aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go('/home');
                    },
                    style: _battlePrimaryButtonStyle(),
                    child: const Text(
                      'Volver a la pantalla principal',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                if (puedeEspectar) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _modoEspectador = true;
                          _comarcaGestionSeleccionada = null;
                        });

                        Navigator.of(dialogContext).pop();
                      },
                      style: _battleSecondaryButtonStyle(),
                      child: const Text(
                        'Espectar partida',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    _hayDialogoPopupActivo = false;
  }

  Future<void> _mostrarArbolTecnologicoModal(BuildContext context) async {
    await _cargarCatalogoTecnologias();
    if (!context.mounted) return;

    final gameState = ref.read(gameProvider);
    final miUsuario = ref.read(authProvider).user?.username ?? '';
    final miEstadoJugador = gameState.jugadores[miUsuario];
    final tecnologiasCompradasSet = <String>{
      ...miEstadoJugador?.tecnologiasCompradas ?? const <String>[],
    };
    final tecnologiasPredesbloqueadasSet = <String>{
      ...miEstadoJugador?.tecnologiasPredesbloqueadas ?? const <String>[],
    };
    final investigandoId = miEstadoJugador?.habilidadInvestigando;
    final catalogError = _techCatalogError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final media = MediaQuery.of(modalContext);
        final availableHeight =
            media.size.height - media.padding.top - media.padding.bottom;

        return SizedBox(
          height: media.size.height,
          child: SafeArea(
            child: Center(
              child: SizedBox(
                width: media.size.width,
                height: availableHeight * 0.9,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                          child: (_techNodes.isEmpty && catalogError != null)
                              ? _CatalogErrorView(
                                  message: catalogError,
                                  onRetry: () async {
                                    Navigator.of(modalContext).pop();
                                    await _mostrarArbolTecnologicoModal(
                                      context,
                                    );
                                  },
                                )
                              : TechTreeView(
                                  nodes: _techNodes,
                                  canvasSize: _techCanvasSize,
                                  ownedTechIds: tecnologiasCompradasSet,
                                  unlockedTechIds:
                                      tecnologiasPredesbloqueadasSet,
                                  investigandoId: investigandoId,
                                  localUsername: miUsuario,
                                  onResearchPressed: _onResearchPressed,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => Navigator.of(modalContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarDialogoMoverConquista({
    required String territorioConquistado,
    required String territorioOrigen,
    required int tropasDisponibles,
  }) async {
    final tropasOrigenActual =
        ref.read(gameProvider).mapa[territorioOrigen]?.units ??
        tropasDisponibles;
    final candidatas = <int>[
      if (tropasDisponibles > 1) tropasDisponibles - 1,
      if (tropasOrigenActual > 1) tropasOrigenActual - 1,
      1,
    ];
    final maxMover = candidatas.first;

    if (maxMover <= 0) {
      if (!mounted) return;
      await _mostrarPopup(
        titulo: 'Conquista pendiente',
        mensaje:
            'No se han podido determinar las tropas disponibles para ocupar ${_formatName(territorioConquistado)}. Sincroniza el estado o reintenta.',
      );
      return;
    }

    int tropasAMover = maxMover;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return _buildBattleDialog(
              context: context,
              maxWidth: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡${_formatName(territorioConquistado)} conquistado!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mueve tropas al nuevo territorio para consolidar la conquista.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '$tropasAMover',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 32,
                        ),
                        color: AppTheme.primary,
                        onPressed: tropasAMover > 1
                            ? () => setDialogState(() => tropasAMover--)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tropasAMover.toDouble(),
                          min: 1,
                          max: maxMover.toDouble(),
                          onChanged: (v) =>
                              setDialogState(() => tropasAMover = v.toInt()),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        color: AppTheme.primary,
                        onPressed: tropasAMover < maxMover
                            ? () => setDialogState(() => tropasAMover++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Disponibles para mover: $maxMover',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final partidaId = ref
                            .read(webSocketProvider)
                            .currentPartidaId;
                        if (partidaId == null) return;

                        try {
                          final dio = ref.read(dioProvider);
                          await dio.post(
                            '/partidas/$partidaId/mover_conquista',
                            data: {'tropas': tropasAMover},
                          );
                          await _sincronizarEstadoPartida(partidaId);
                          ref
                              .read(gameProvider.notifier)
                              .limpiarSeleccionCombate();
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                        } on DioException catch (e) {
                          final detalle =
                              e.response?.data?.toString() ?? e.message;
                          debugPrint('🔴 ERROR mover_conquista: $detalle');
                          if (!mounted || !dialogContext.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $detalle')),
                          );
                        }
                      },
                      style: _battlePrimaryButtonStyle().copyWith(
                        padding: WidgetStatePropertyAll(
                          const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                      child: const Text(
                        'Mover tropas',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CatalogErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _CatalogErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.primary,
              size: 36,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.text, fontSize: 14),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionBubbleData {
  final String jugador;
  final String tipo;
  final String contenido;

  const _ReactionBubbleData({
    required this.jugador,
    required this.tipo,
    required this.contenido,
  });
}

class _ReactionBubbleView extends ConsumerWidget {
  final _ReactionBubbleData data;
  final String Function(String fileName) imageUrlBuilder;

  const _ReactionBubbleView({
    required this.data,
    required this.imageUrlBuilder,
  });

  bool get _isImage {
    return data.tipo == 'reaccion' ||
        RegExp(
          r'\.(png|jpe?g|webp|gif|avif)$',
          caseSensitive: false,
        ).hasMatch(data.contenido);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final numeroJugador = gameState.jugadores[data.jugador]?.numeroJugador;
    final borderColor = numeroJugador == null
        ? AppTheme.goldMain
        : ColorUtils.getPlayerColor(numeroJugador);

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, _isImage ? -12 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(10, 18),
              painter: _ReactionBubbleTailPainter(borderColor: borderColor),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: EdgeInsets.symmetric(
                horizontal: _isImage ? 2 : 12,
                vertical: _isImage ? 2 : 9,
              ),
              decoration: BoxDecoration(
                color: AppTheme.panelBg.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.85),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isImage
                  ? Image.network(
                      imageUrlBuilder(data.contenido),
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.add_reaction_outlined,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    )
                  : Text(
                      data.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionBubbleTailPainter extends CustomPainter {
  final Color borderColor;

  const _ReactionBubbleTailPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppTheme.panelBg.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = borderColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _ReactionBubbleTailPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

class _PlayerInfoPanel extends StatelessWidget {
  final GameState gameState;
  final String jugadorLocalId;
  final double panelHeight;

  const _PlayerInfoPanel({
    required this.gameState,
    required this.jugadorLocalId,
    required this.panelHeight,
  });

  @override
  Widget build(BuildContext context) {
    final jugadores = gameState.jugadores.entries.toList(growable: false)
      ..sort((a, b) => a.value.numeroJugador.compareTo(b.value.numeroJugador));

    return SizedBox(
      width: 208,
      child: SizedBox(
        height: panelHeight,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final jugador in jugadores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Transform.scale(
                      scale: gameState.turnoDe == jugador.key ? 1.08 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _PlayerInfoTile(
                          username: jugador.key,
                          numeroJugador: jugador.value.numeroJugador,
                          esTurnoActual: gameState.turnoDe == jugador.key,
                          esJugadorLocal: jugador.key == jugadorLocalId,
                          avatar: jugador.value.avatar,
                          castillos: _contarComarcasDeJugador(jugador.key),
                          tropas: _sumarTropasDeJugador(jugador.key),
                          monedas: jugador.value.monedas,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _contarComarcasDeJugador(String jugadorId) {
    return gameState.mapa.values.where((t) => t.ownerId == jugadorId).length;
  }

  int _sumarTropasDeJugador(String jugadorId) {
    return gameState.mapa.values
        .where((t) => t.ownerId == jugadorId)
        .fold<int>(0, (sum, t) => sum + t.units);
  }
}

class _PlayerInfoTile extends StatelessWidget {
  final String username;
  final int numeroJugador;
  final bool esTurnoActual;
  final bool esJugadorLocal;
  final String? avatar;
  final int castillos;
  final int tropas;
  final int monedas;

  const _PlayerInfoTile({
    required this.username,
    required this.numeroJugador,
    required this.esTurnoActual,
    required this.esJugadorLocal,
    required this.avatar,
    required this.castillos,
    required this.tropas,
    required this.monedas,
  });

  @override
  Widget build(BuildContext context) {
    final colorJugador = ColorUtils.getPlayerColor(numeroJugador);
    final borderColor = colorJugador;
    final borderWidth = esTurnoActual ? 3.5 : 1.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF202229).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.9),
          width: borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorJugador,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.castle_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$castillos',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$tropas',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (esJugadorLocal) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.monetization_on,
                        size: 13,
                        color: AppTheme.borderGoldVivo,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$monedas',
                        style: const TextStyle(
                          color: AppTheme.borderGoldVivo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppAvatar(
            avatar: avatar,
            radius: 18,
            backgroundColor: const Color(0xFF15171D),
            iconColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}
