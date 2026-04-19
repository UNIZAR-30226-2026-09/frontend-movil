import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/features/map/services/map_loader.dart';
import 'package:soberania/features/map/widgets/action_panel.dart';
import 'package:soberania/features/map/widgets/interactive_game_map.dart';
import 'package:soberania/features/game/data/tech_tree_data.dart';
import 'package:soberania/features/game/widgets/tech_tree_view.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/api/dio_provider.dart';

class BatallaScreen extends ConsumerStatefulWidget {
  const BatallaScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<BatallaScreen> createState() => _BatallaScreenState();
}

class _BatallaScreenState extends ConsumerState<BatallaScreen> {
  late final Future<GameMap> _mapFuture;
  bool _partidaTerminada = false;
  bool _cargandoCatalogoTecnologias = false;
  Map<String, int> _techPrices = const <String, int>{};
  Map<String, String> _techDescriptions = const <String, String>{};
  Map<String, String> _techNames = const <String, String>{};

  void _onResearchPressed(String techId, int cost) {
    final partidoId = ref.read(webSocketProvider).currentPartidaId;
    final partidaTexto = partidoId == null ? '' : ' (partida $partidoId)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Investigar "$techId" cuesta $cost.$partidaTexto La compra real se activara cuando backend publique el endpoint de investigacion.',
        ),
      ),
    );
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

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _normalizeTechId(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return normalized.replaceAll(RegExp(r'_+'), '_');
  }

  Map<String, int> _parsePrecios(Map<String, dynamic> data) {
    final precios = <String, int>{};
    final raw = data['precios'];
    if (raw is! Map) return precios;

    for (final entry in raw.entries) {
      final id = _normalizeTechId(entry.key.toString());
      if (id.isEmpty) continue;
      final cost = _toInt(entry.value);
      if (cost != null) {
        precios[id] = cost;
      }
    }

    return precios;
  }

  Map<String, dynamic>? _extractCatalogPayload(dynamic raw) {
    if (raw is! Map) return null;

    final root = Map<String, dynamic>.from(raw);
    if (root.containsKey('precios') || root.containsKey('arbol')) {
      return root;
    }

    final data = root['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      if (nested.containsKey('precios') || nested.containsKey('arbol')) {
        return nested;
      }
    }

    final tecnologias = root['tecnologias'];
    if (tecnologias is Map) {
      return <String, dynamic>{
        'arbol': Map<String, dynamic>.from(tecnologias),
        'precios': root['precios'],
      };
    }

    return null;
  }

  ({
    Map<String, int> prices,
    Map<String, String> names,
    Map<String, String> descriptions,
  })
  _parseArbol(Map<String, dynamic> data) {
    final prices = <String, int>{};
    final names = <String, String>{};
    final descriptions = <String, String>{};
    final raw = data['arbol'];

    void parseNode(String id, Map<String, dynamic> nodeData) {
      final key = _normalizeTechId(id);
      if (key.isEmpty) return;

      final name = nodeData['nombre'] ?? nodeData['name'] ?? nodeData['titulo'];
      if (name is String && name.trim().isNotEmpty) {
        names[key] = name.trim();
      }

      final description =
          nodeData['descripcion'] ??
          nodeData['description'] ??
          nodeData['detalle'];
      if (description is String && description.trim().isNotEmpty) {
        descriptions[key] = description.trim();
      }

      final cost = _toInt(
        nodeData['coste'] ?? nodeData['costo'] ?? nodeData['cost'],
      );
      if (cost != null) {
        prices[key] = cost;
      }
    }

    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        parseNode(
          entry.key.toString(),
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    } else if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final asMap = Map<String, dynamic>.from(item);
        final idRaw =
            (asMap['id'] ?? asMap['clave'] ?? asMap['key'])?.toString() ?? '';
        final id = _normalizeTechId(idRaw);
        if (id.isEmpty) continue;
        parseNode(id, asMap);
      }
    }

    return (prices: prices, names: names, descriptions: descriptions);
  }

  Future<void> _cargarCatalogoTecnologias() async {
    if (_cargandoCatalogoTecnologias) return;
    _cargandoCatalogoTecnologias = true;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/partidas/tecnologias');

      final data = _extractCatalogPayload(response.data);
      if (data == null) return;

      final precios = _parsePrecios(data);
      final arbol = _parseArbol(data);

      if (!mounted) return;
      setState(() {
        final mergedPrices = <String, int>{...precios, ...arbol.prices};
        if (mergedPrices.isNotEmpty) {
          _techPrices = mergedPrices;
        }
        if (arbol.names.isNotEmpty) {
          _techNames = arbol.names;
        }
        if (arbol.descriptions.isNotEmpty) {
          _techDescriptions = arbol.descriptions;
        }
      });
    } on DioException catch (e) {
      // En main puede no existir este endpoint: mantenemos fallback local.
      debugPrint(
        'No se pudo cargar catalogo de tecnologias: ${e.response?.statusCode} ${e.message}',
      );
    } catch (e) {
      debugPrint('Error parseando catalogo de tecnologias: $e');
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
      final esFaseRefuerzo =
          faseActual == 'refuerzo' || faseActual == 'reclutamiento';
      final esMiTurno = next.turnoDe == miUsuario;
      final ahoraDebeAvisar = esFaseRefuerzo && esMiTurno;

      final faseAnterior = previous?.faseActual.toLowerCase();
      final antesEraFaseRefuerzo =
          faseAnterior == 'refuerzo' || faseAnterior == 'reclutamiento';
      final antesEraMiTurno = previous?.turnoDe == miUsuario;
      final antesDebiaAvisar = antesEraFaseRefuerzo && antesEraMiTurno;

      // Solo avisamos al entrar en refuerzo/reclutamiento de nuestro turno.
      if (!ahoraDebeAvisar || antesDebiaAvisar) return;

      final tropasRecibidas = next.jugadores[miUsuario]?.tropasReserva ?? 0;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Has recibido $tropasRecibidas tropas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    });

    ref.listen<WebSocketState>(webSocketProvider, (previous, next) {
      final prevVersion = previous?.versionEventoSistema ?? 0;
      if (next.versionEventoSistema <= prevVersion) return;

      final tipo = next.tipoEventoSistema;
      if (tipo == null) return;

      final miUsuario = ref.read(authProvider).user?.username;

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
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final titulo = 'Ataque en ${_formatName(resultado.destino)}';
            final mensaje =
                'Has perdido ${resultado.bajasAtacante} tropa(s). '
                'El enemigo perdió ${resultado.bajasDefensor} tropa(s). '
                '${resultado.victoria ? '¡Territorio conquistado!' : 'El territorio resiste.'}';

            return AlertDialog(
              title: Text(titulo),
              content: Text(mensaje),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(gameProvider.notifier).limpiarResultadoAtaque();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );

        // Si fue victoria, el backend bloquea ataques hasta que movamos tropas
        if (resultado.victoria && mounted) {
          await _mostrarDialogoMoverConquista(resultado.destino);
        }
      });
    });

    return Scaffold(
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
                  ref
                      .read(gameProvider.notifier)
                      .seleccionarComarca(
                        c.id,
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
                      onPressed: () => context.pop(),
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

  Future<void> _mostrarDialogoSistemaYSalir(
    String titulo,
    String mensaje,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  context.go('/lobby');
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarArbolTecnologicoModal(BuildContext context) async {
    await _cargarCatalogoTecnologias();

    final gameState = ref.read(gameProvider);
    final miUsuario = ref.read(authProvider).user?.username ?? '';
    final miEstadoJugador = gameState.jugadores[miUsuario];
    final tecnologiasCompradas =
        miEstadoJugador?.tecnologiasCompradas ?? const <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final media = MediaQuery.of(context);
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
                          child: TechTreeView(
                            nodes: TechTreeData.nodes,
                            canvasSize: TechTreeData.canvasSize,
                            backendPrices: _techPrices,
                            backendDescriptions: _techDescriptions,
                            backendNames: _techNames,
                            ownedTechIds: tecnologiasCompradas,
                            onResearchPressed: _onResearchPressed,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                      if (!dialogContext.mounted) return;
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
