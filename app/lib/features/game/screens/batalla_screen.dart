import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/features/game/services/tech_catalog_service.dart';
import 'package:soberania/features/map/services/map_loader.dart';
import 'package:soberania/features/map/widgets/action_panel.dart';
import 'package:soberania/features/map/widgets/interactive_game_map.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';
import 'package:soberania/features/game/widgets/tech_tree_view.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/api/dio_provider.dart';

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
  bool _cargandoCatalogoTecnologias = false;
  bool _hayDialogoPopupActivo = false;
  List<TechNodeModel> _techNodes = const <TechNodeModel>[];
  Size _techCanvasSize = const Size(1200, 790);
  Set<String> _techCatalogUnlockedIds = const <String>{};
  Set<String> _techCatalogOwnedIds = const <String>{};
  bool _techCatalogHasAuthoritativeAvailability = false;
  String? _techCatalogError;

  TechCatalogService get _techCatalogService =>
      TechCatalogService(ref.read(dioProvider));

  int _partidaIdActual() {
    if (widget.partidaId > 0) return widget.partidaId;
    return ref.read(webSocketProvider).currentPartidaId ?? 0;
  }

  Future<void> _sincronizarEstadoPartida(int partidaId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/partidas/$partidaId/estado');
    if (response.data is! Map) return;

    final payload = Map<String, dynamic>.from(response.data as Map);
    ref.read(gameProvider.notifier).actualizarDesdeServidor(payload);
  }

  void _onResearchPressed(String techId, int cost) async {
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
        technologyId: techId,
      );

      final jugadorId = ref.read(authProvider).user?.username ?? '';
      if (jugadorId.isNotEmpty) {
        ref
            .read(gameProvider.notifier)
            .marcarTecnologiaComprada(
              jugadorId: jugadorId,
              tecnologiaId: techId,
            );
      }

      await _sincronizarEstadoPartida(partidaId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tecnología comprada: $techId ($cost monedas).'),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final detalle = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ??
                e.message ??
                'No se pudo comprar la tecnología')
          : (e.message ?? 'No se pudo comprar la tecnología');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(detalle)));
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

  @override
  void initState() {
    super.initState();
    _mapFuture = MapLoader.loadMap();

    // Precargamos el catalogo para que el modal abra con datos frescos
    // cuando el backend expone precios/descripciones dinamicos.
    Future<void>.microtask(_cargarCatalogoTecnologias);
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
        _techCatalogUnlockedIds = catalog.unlockedTechIds;
        _techCatalogOwnedIds = catalog.ownedTechIds;
        _techCatalogHasAuthoritativeAvailability =
            catalog.hasAuthoritativeAvailability;
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

      final faseActual = next.faseActual.toLowerCase();
      final faseAnterior = previous?.faseActual.toLowerCase();

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

        if (tipo == 'VOTACION_PAUSA_INICIADA') {
        final solicitante =
            (payload['jugador_solicitante'] ?? next.jugadorEventoSistema)
                ?.toString() ??
            '';

        if (miUsuario != null && miUsuario.isNotEmpty && solicitante == miUsuario) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final voto = await _mostrarPopupDecision(
            titulo: 'Pausar partida',
            mensaje: 'El jugador $solicitante propone pausar. ¿Pausar partida?',
          );
          if (!mounted) return;

          final partidaId = _partidaIdActual();
          if (partidaId <= 0) return;

          try {
            await ref
                .read(dioProvider)
                .post(
                  '/partidas/$partidaId/pausa/votar',
                  data: {'aceptar': voto == true},
                );
          } on DioException catch (e) {
            if (!mounted) return;
            final detalle = e.response?.data is Map<String, dynamic>
                ? (e.response?.data['detail']?.toString() ??
                      e.message ??
                      'No se pudo registrar tu voto')
                : (e.message ?? 'No se pudo registrar tu voto');
            unawaited(
              _mostrarPopup(
                titulo: 'Error al votar pausa',
                mensaje: detalle,
              ),
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

      if (tipo == 'PAUSA_APROBADA') {
        _partidaTerminada = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_hayDialogoPopupActivo) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          unawaited(
            _mostrarPopup(
              titulo: 'Partida pausada',
              mensaje: 'La pausa fue aprobada. Volverás al lobby.',
              alAceptar: () {
                if (mounted) context.go('/inicio');
              },
            ),
          );
        });
        return;
      }

      if (tipo == 'JUGADOR_ELIMINADO') {
        _partidaTerminada = true;
        final jugador = next.jugadorEventoSistema ?? 'Desconocido';
        final esYo = miUsuario != null && jugador == miUsuario;

        final titulo = esYo ? 'Has sido eliminado' : 'Jugador eliminado';
        final mensaje = esYo
            ? 'Te han eliminado de la partida. Volverás al lobby.'
            : '$jugador ha sido eliminado de la partida. Regresarás al lobby.';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarDialogoSistemaYSalir(titulo, mensaje);
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
      if (_partidaTerminada) return;

      final prevVersion = previous?.versionResultadoAtaque ?? 0;
      final hayNuevoResultado =
          next.ultimoResultadoAtaque != null &&
          next.versionResultadoAtaque > prevVersion;

      if (!hayNuevoResultado) return;

      final resultado = next.ultimoResultadoAtaque!;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Mostramos el resultado del combate
        await _mostrarPopup(
          titulo: 'Ataque en ${_formatName(resultado.destino)}',
          mensaje:
              'Has perdido ${resultado.bajasAtacante} tropa(s).\n'
              'El enemigo perdió ${resultado.bajasDefensor} tropa(s).\n'
              '${resultado.victoria ? '¡Territorio conquistado!' : 'El territorio resiste.'}',
          alAceptar: () =>
              ref.read(gameProvider.notifier).limpiarResultadoAtaque(),
        );

        // Si fue victoria, el backend bloquea ataques hasta que movamos tropas
        if (resultado.victoria && mounted) {
          await _mostrarDialogoMoverConquista(resultado.destino);
        }
      });
    });

    final miUsuarioHud = ref.watch(
      authProvider.select((auth) => auth.user?.username ?? ''),
    );
    // Sacamos las monedas del jugador local para pintarlas en la barra superior.
    final monedasHud = ref.watch(
      gameProvider.select((state) {
        if (miUsuarioHud.isEmpty) return 0;
        final miEstadoJugador = state.jugadores[miUsuarioHud];
        return miEstadoJugador?.monedas ?? 0;
      }),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppTheme.borderGoldVivo,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '$monedasHud',
                  style: const TextStyle(
                    color: AppTheme.borderGoldVivo,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  final estadoActual = ref.read(gameProvider);
                  final miUsuario = ref.read(authProvider).user?.username ?? '';
                  final faseActual = estadoActual.faseActual.toLowerCase();

                  if (faseActual == 'gestion') {
                    final ownerId = estadoActual.mapa[c.id]?.ownerId ?? '';
                    final esComarcaPropia =
                        miUsuario.isNotEmpty && ownerId == miUsuario;

                    // En gestión solo abrimos menú sobre comarcas propias.
                    if (!esComarcaPropia) return;

                    _mostrarOpcionesGestionComarca(c.id, widget.partidaId);
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
              const ActionPanel(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      // go_router para navegar — consistente con el resto de la app
                      onPressed: () async {
                        final confirmar = await _mostrarPopupDecision(
                          titulo: '¿Pausar partida?',
                          mensaje: '¿Quieres proponer pausa?',
                        );

                        if (confirmar == true) {
                          unawaited(
                            _mostrarPopup(
                              titulo: 'Votación',
                              mensaje: 'Esperando al resto de jugadores...',
                            ),
                          );

                          final partidaId = _partidaIdActual();
                          if (partidaId <= 0) {
                            if (_hayDialogoPopupActivo) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                            unawaited(
                              _mostrarPopup(
                                titulo: 'Error al pausar',
                                mensaje:
                                    'No se pudo identificar la partida actual.',
                              ),
                            );
                            return;
                          }

                          try {
                            await ref
                                .read(dioProvider)
                                .post('/partidas/$partidaId/pausa/solicitar');
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
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
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
                  child: Material(
                    color: AppTheme.secondary,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppTheme.primary, width: 1.6),
                    ),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _mostrarArbolTecnologicoModal(context),
                      child: const SizedBox(
                        width: 78,
                        height: 78,
                        child: Icon(
                          Icons.park_rounded,
                          color: AppTheme.primary,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _mostrarOpcionesGestionComarca(
    String comarcaId,
    int partidaId,
  ) async {
    if (!mounted) return;

    final partidaIdEfectiva = partidaId > 0
        ? partidaId
        : (ref.read(webSocketProvider).currentPartidaId ?? 0);

    if (partidaIdEfectiva <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la partida actual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Las tres ramas disponibles — coinciden exactamente con las claves
    // del ARBOL_TECNOLOGICO del backend (minúsculas, sin tildes).
    const ramas = [
      _RamaInfo(
        'artilleria',
        '💣',
        'Artillería',
        'Mortero → Misil → Bomba nuclear',
      ),
      _RamaInfo(
        'logistica',
        '🏛️',
        'Logística',
        'Academia → Propaganda → Sanciones',
      ),
      _RamaInfo(
        'biologica',
        '🦠',
        'Biológica',
        'Gripe → Vacuna/Fatiga → Coronavirus',
      ),
    ];

    String ramaSeleccionada = 'artilleria';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // isScrollControlled para que el sheet no se corte si hay mucho contenido.
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opciones de Gestión',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- MINA ---
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.monetization_on,
                          color: AppTheme.borderGoldVivo,
                        ),
                        title: const Text(
                          'Mandar a la mina (Generar Monedas)',
                          style: TextStyle(color: AppTheme.text),
                        ),
                        onTap: () async {
                          try {
                            await ref
                                .read(dioProvider)
                                .post(
                                  '/partidas/$partidaIdEfectiva/trabajar',
                                  data: {'territorio_id': comarcaId},
                                );
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comarca enviada a la mina'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } on DioException catch (e) {
                            if (!mounted) return;
                            final detalle =
                                e.response?.data is Map<String, dynamic>
                                ? (e.response?.data['detail']?.toString() ??
                                      e.message ??
                                      'Error al enviar comarca a la mina')
                                : (e.message ??
                                      'Error al enviar comarca a la mina');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(detalle),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),

                      const Divider(color: AppTheme.borderGold),

                      // --- LABORATORIO ---
                      const Text(
                        'Mandar al laboratorio (Investigar)',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Elige la rama tecnológica a investigar:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Selector de rama — tres opciones como cards seleccionables.
                      ...ramas.map((rama) {
                        final seleccionada = ramaSeleccionada == rama.id;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => ramaSeleccionada = rama.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: seleccionada
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: seleccionada
                                    ? AppTheme.primary
                                    : AppTheme.borderGold,
                                width: seleccionada ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  rama.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rama.nombre,
                                        style: TextStyle(
                                          color: seleccionada
                                              ? AppTheme.primary
                                              : AppTheme.text,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        rama.descripcion,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (seleccionada)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(dioProvider)
                                  .post(
                                    '/partidas/$partidaIdEfectiva/investigar',
                                    data: {
                                      'territorio_id': comarcaId,
                                      'rama': ramaSeleccionada,
                                    },
                                  );
                              if (!mounted || !sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              final label = ramas
                                  .firstWhere((r) => r.id == ramaSeleccionada)
                                  .nombre;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Comarca investigando: $label'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } on DioException catch (e) {
                              if (!mounted) return;
                              final detalle =
                                  e.response?.data is Map<String, dynamic>
                                  ? (e.response?.data['detail']?.toString() ??
                                        e.message ??
                                        'Error al iniciar investigación')
                                  : (e.message ??
                                        'Error al iniciar investigación');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(detalle),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.science_rounded),
                          label: const Text('Investigar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F0F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGoldVivo, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.borderGoldVivo,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      alAceptar?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.borderGoldVivo,
                      foregroundColor: const Color(0xFF1A1200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _hayDialogoPopupActivo = false;
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F0F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGoldVivo, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.borderGoldVivo,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.borderGoldVivo,
                      foregroundColor: const Color(0xFF1A1200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SÍ',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A2E1A),
                      foregroundColor: AppTheme.text,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: AppTheme.borderGoldVivo,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'NO',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
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

  Future<void> _mostrarArbolTecnologicoModal(BuildContext context) async {
    await _cargarCatalogoTecnologias();
    if (!context.mounted) return;

    final gameState = ref.read(gameProvider);
    final miUsuario = ref.read(authProvider).user?.username ?? '';
    final miEstadoJugador = gameState.jugadores[miUsuario];
    final tecnologiasCompradas =
        miEstadoJugador?.tecnologiasCompradas ?? const <String>[];
    final tecnologiasPredesbloqueadas =
        miEstadoJugador?.tecnologiasPredesbloqueadas ?? const <String>[];
    final tecnologiasCompradasSet = <String>{
      ...tecnologiasCompradas,
      ..._techCatalogOwnedIds,
    };
    final tecnologiasPredesbloqueadasSet = <String>{
      ...tecnologiasPredesbloqueadas,
      ..._techCatalogUnlockedIds,
      ..._techCatalogOwnedIds,
    };
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
                width: media.size.width - 8,
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
                                  authoritativeUnlocks:
                                      _techCatalogHasAuthoritativeAvailability,
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

  Future<void> _mostrarDialogoMoverConquista(
    String territorioConquistado,
  ) async {
    final origen = ref.read(gameProvider).origenSeleccionado;
    final tropasOrigen = ref.read(gameProvider).mapa[origen]?.units ?? 1;

    // Máximo movible: todas menos 1 que se queda de guarnición en origen.
    // Si origen tiene 1 tropa el clamp lo fuerza a 1 — el backend lo rechazará
    // pero al menos el diálogo no peta.
    final maxMover = (tropasOrigen - 1).clamp(1, tropasOrigen - 1);
    int tropasAMover = maxMover;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(
                '¡${_formatName(territorioConquistado)} conquistado!',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mueve tropas al nuevo territorio para consolidar la conquista.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$tropasAMover',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
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
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        onPressed: tropasAMover < maxMover
                            ? () => setDialogState(() => tropasAMover++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
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
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } on DioException catch (e) {
                      final detalle = e.response?.data?.toString() ?? e.message;
                      debugPrint('🔴 ERROR mover_conquista: $detalle');
                      if (!mounted || !dialogContext.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $detalle')),
                      );
                    }
                  },
                  child: const Text('Mover tropas'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Datos de cada rama tecnológica — se usan solo en el selector del bottom sheet.
class _RamaInfo {
  final String id;
  final String emoji;
  final String nombre;
  final String descripcion;

  const _RamaInfo(this.id, this.emoji, this.nombre, this.descripcion);
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
