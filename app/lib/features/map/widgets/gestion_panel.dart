import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/features/game/data/tech_tree_data.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/api/dio_provider.dart';

class GestionPanel extends ConsumerStatefulWidget {
  const GestionPanel({
    super.key,
    required this.comarcaId,
    required this.partidaId,
    required this.onClose,
    this.techNodes = const <TechNodeModel>[],
  });

  final String comarcaId;
  final int partidaId;
  final VoidCallback onClose;
  final List<TechNodeModel> techNodes;

  @override
  ConsumerState<GestionPanel> createState() => _GestionPanelState();
}

class _GestionPanelState extends ConsumerState<GestionPanel> {
  static const List<_RamaInfo> ramas = [
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

  late String ramaSeleccionada;
  late String habilidadSeleccionada;

  @override
  void initState() {
    super.initState();
    ramaSeleccionada = 'artilleria';
    habilidadSeleccionada = _habilidadesDeRama(ramaSeleccionada).first.id;
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

  List<TechNodeModel> _habilidadesDeRama(String ramaId) {
    final source = widget.techNodes.isNotEmpty
        ? widget.techNodes
        : TechTreeData.nodes;

    switch (ramaId) {
      case 'artilleria':
        return source
            .where((node) => node.branch == TechBranch.artilleria)
            .toList(growable: false);
      case 'logistica':
        return source
            .where((node) => node.branch == TechBranch.operaciones)
            .toList(growable: false);
      case 'biologica':
        return source
            .where((node) => node.branch == TechBranch.biologica)
            .toList(growable: false);
      default:
        return const <TechNodeModel>[];
    }
  }

  int _partidaIdEfectiva() {
    if (widget.partidaId > 0) return widget.partidaId;
    return ref.read(webSocketProvider).currentPartidaId ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final partidaIdEfectiva = _partidaIdEfectiva();
    final panelMaxHeight = MediaQuery.of(context).size.height * 0.74;
    final username = ref.watch(authProvider).user?.username ?? '';
    final playerState = ref.watch(gameProvider).jugadores[username];
    final ownedTechs = <String>{
      ...(playerState?.tecnologiasCompradas ?? const <String>[]),
    };
    final predesbloqueadas = <String>{
      ...(playerState?.tecnologiasPredesbloqueadas ?? const <String>[]),
    };
    final investigandoId = playerState?.habilidadInvestigando;

    bool isOwned(TechNodeModel node) => ownedTechs.contains(node.id);

    bool isInvestigating(TechNodeModel node) =>
        investigandoId != null &&
        investigandoId.isNotEmpty &&
        investigandoId == node.id;

    /// Cascada de 5 reglas (igual que TechTreeView):
    /// Raíz sin prerrequisito ⇒ investigable.
    /// Padre predesbloqueado o comprado ⇒ investigable.
    bool isUnlocked(TechNodeModel node) {
      if (isOwned(node)) return true;
      if (predesbloqueadas.contains(node.id)) return true;
      if (node.prerequisites.isEmpty) return true;
      return node.prerequisites.any(
        (pid) => predesbloqueadas.contains(pid) || ownedTechs.contains(pid),
      );
    }

    bool canResearch(TechNodeModel node) =>
        !isOwned(node) && !isInvestigating(node) && isUnlocked(node);

    final habilidadesActuales = _habilidadesDeRama(ramaSeleccionada);
    if (habilidadesActuales.isNotEmpty &&
        !habilidadesActuales.any((node) => node.id == habilidadSeleccionada)) {
      habilidadSeleccionada = habilidadesActuales.first.id;
    }
    TechNodeModel? selectedNode;
    for (final node in habilidadesActuales) {
      if (node.id == habilidadSeleccionada) {
        selectedNode = node;
        break;
      }
    }
    final puedeInvestigarSeleccion =
        selectedNode != null && canResearch(selectedNode);

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: panelMaxHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatName(widget.comarcaId),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Divider(
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  height: 18,
                  thickness: 1,
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (partidaIdEfectiva <= 0) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo identificar la partida actual'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      try {
                        await ref.read(dioProvider).post(
                          '/partidas/$partidaIdEfectiva/trabajar',
                          data: {'territorio_id': widget.comarcaId},
                        );
                        if (!mounted) return;
                        ref.read(gameProvider.notifier)
                            .actualizarEstadoBloqueo(widget.comarcaId, 'trabajando');
                        widget.onClose();
                        // Formateamos el nombre de la comarca para que se vea bonito
                        final nombreComarca = widget.comarcaId.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

                        showDialog(
                          context: context,
                          builder: (ctx) {
                            // Cerramos el popup automáticamente a los 2 segundos
                            Future.delayed(const Duration(seconds: 2), () {
                              if (Navigator.of(ctx).canPop()) {
                                Navigator.of(ctx).pop();
                              }
                            });

                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.95), // Fondo oscuro panel
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37), // Dorado clásico
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.agriculture_rounded, // Icono de trabajar
                                      color: Color(0xFFD4AF37),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '¡$nombreComarca trabajando!',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        
                        // Marcar trabajo completado y verificar si ambas acciones están hechas
                        ref.read(gameProvider.notifier).marcarTrabajoCompletado();
                        
                        // Si ya ha investigado también, pasar de fase automáticamente
                        if (ref.read(gameProvider.notifier).ambosAccionesGestionCompletadas()) {
                          Future.delayed(const Duration(seconds: 2), () async {
                            if (!mounted) return;
                            final dio = ref.read(dioProvider);
                            try {
                              await dio.post('/partidas/$partidaIdEfectiva/pasar_fase');
                              // El backend notificará el cambio de fase por WebSocket
                            } catch (e) {
                              debugPrint('Error pasando de fase automáticamente: $e');
                            }
                          });
                        }
                      } on DioException catch (e) {
                        if (!mounted) return;
                        final detalle =
                            e.response?.data is Map<String, dynamic>
                            ? (e.response?.data['detail']?.toString() ??
                                  e.message ??
                                  'Ya has realizado una acción de gestión este turno.')
                            : (e.message ?? 'Ya has realizado una acción de gestión este turno.');
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
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFBF5050), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    detalle,
                                    style: const TextStyle(color: Color(0xFFE89090), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              size: 20,
                              color: AppTheme.borderGoldVivo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mandar a la mina',
                                  style: TextStyle(
                                    color: AppTheme.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Generar monedas con esta comarca',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.primary.withValues(alpha: 0.75),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Divider(
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  height: 18,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.science_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mandar al laboratorio',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Elige una rama y una habilidad para poner esta comarca a investigar.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Elige la rama tecnológica:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...ramas.map((rama) {
                        final seleccionada = ramaSeleccionada == rama.id;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                ramaSeleccionada = rama.id;
                                habilidadSeleccionada =
                                    _habilidadesDeRama(rama.id).first.id;
                              });
                            },
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: seleccionada
                                      ? AppTheme.primary
                                      : AppTheme.primary.withValues(alpha: 0.30),
                                  width: seleccionada ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.primary.withValues(alpha: 0.22),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      rama.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          rama.descripcion,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (seleccionada)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      const Text(
                        'Elige la habilidad exacta a investigar:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (habilidadesActuales.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'El backend no devolvió habilidades para esta rama.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ...habilidadesActuales.map((habilidad) {
                        final seleccionada = habilidadSeleccionada == habilidad.id;
                        final bloqueada = !isUnlocked(habilidad) && !isOwned(habilidad);
                        final investigada = isOwned(habilidad);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: bloqueada
                                ? null
                                : () {
                                    setState(() {
                                      habilidadSeleccionada = habilidad.id;
                                    });
                                  },
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: bloqueada ? 0.06 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: seleccionada
                                      ? AppTheme.primary
                                      : AppTheme.primary.withValues(alpha: 0.30),
                                  width: seleccionada ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: bloqueada ? 0.10 : 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.primary.withValues(alpha: 0.22),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      habilidad.icon,
                                      color: seleccionada
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habilidad.name,
                                          style: TextStyle(
                                            color: seleccionada
                                                ? AppTheme.primary
                                                : (bloqueada
                                                      ? AppTheme.textSecondary
                                                      : AppTheme.text),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          habilidad.id,
                                          style: TextStyle(
                                            color: bloqueada
                                                ? AppTheme.textSecondary
                                                : AppTheme.textSecondary,
                                            fontSize: 11,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (investigada)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF74D67A),
                                      size: 20,
                                    )
                                  else if (bloqueada)
                                    const Icon(
                                      Icons.lock_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 18,
                                    )
                                  else if (seleccionada)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: puedeInvestigarSeleccion
                              ? () async {
                            if (partidaIdEfectiva <= 0) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No se pudo identificar la partida actual'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            try {
                              // ─── DEBUG ──────────────────────────────────────
                              print('[DEBUG PAYLOAD INVESTIGAR] territorio_id: ${widget.comarcaId}, habilidad_id: $habilidadSeleccionada');
                              // ────────────────────────────────────────────────
                              await ref.read(dioProvider).post(
                                '/partidas/$partidaIdEfectiva/investigar',
                                data: {
                                  'territorio_id': widget.comarcaId,
                                  'habilidad_id': habilidadSeleccionada,
                                },
                              );
                              // ─── DEBUG ──────────────────────────────────────
                              print('[DEBUG INVESTIGACION ACEPTADA] territorio=${widget.comarcaId}, habilidad=$habilidadSeleccionada');
                              // ────────────────────────────────────────────────
                              if (!mounted) return;
                              ref.read(gameProvider.notifier)
                                  .actualizarEstadoBloqueo(widget.comarcaId, 'investigando');
                              widget.onClose();
                              final label = ramas
                                  .firstWhere((r) => r.id == ramaSeleccionada)
                                  .nombre;
                              final nombreComarca = widget.comarcaId.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (Navigator.of(ctx).canPop()) {
                                      Navigator.of(ctx).pop();
                                    }
                                  });

                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.science_rounded, // Icono de investigación
                                            color: Color(0xFFD4AF37),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '¡$nombreComarca\ninvestigando $label!',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFFE0E0E0),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              // Marcar investigación completada y verificar si ambas acciones están hechas
                              ref.read(gameProvider.notifier).marcarInvestigacionCompletada();
                              
                              // Si ya ha trabajado también, pasar de fase automáticamente
                              if (ref.read(gameProvider.notifier).ambosAccionesGestionCompletadas()) {
                                Future.delayed(const Duration(seconds: 2), () async {
                                  if (!mounted) return;
                                  final dio = ref.read(dioProvider);
                                  try {
                                    await dio.post('/partidas/$partidaIdEfectiva/pasar_fase');
                                    // El backend notificará el cambio de fase por WebSocket
                                  } catch (e) {
                                    debugPrint('Error pasando de fase automáticamente: $e');
                                  }
                                });
                              }
                            } on DioException catch (e) {
                              if (!mounted) return;
                              final detalle =
                                  e.response?.data is Map<String, dynamic>
                                  ? (e.response?.data['detail']?.toString() ??
                                        e.message ??
                                        'Ya has realizado una acción de gestión este turno.')
                                  : (e.message ?? 'Ya has realizado una acción de gestión este turno.');
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
                                      const Icon(Icons.error_outline_rounded, color: Color(0xFFBF5050), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          detalle,
                                          style: const TextStyle(color: Color(0xFFE89090), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                              : null,
                          icon: const Icon(Icons.science_rounded),
                          label: const Text(
                            'Investigar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 3,
                            backgroundColor: const Color(0xFF3A2A16),
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.75),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],  
            ),
          ),
        ),
      ),
    );
  }
}

class _RamaInfo {
  final String id;
  final String emoji;
  final String nombre;
  final String descripcion;

  const _RamaInfo(this.id, this.emoji, this.nombre, this.descripcion);
}
