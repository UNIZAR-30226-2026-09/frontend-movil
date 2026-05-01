import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soberania/app/theme/app_theme.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/models/special_attack_model.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';
import 'package:soberania/features/game/providers/game_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/shared/api/dio_provider.dart';

class ActionPanel extends ConsumerStatefulWidget {
  const ActionPanel({
    super.key,
    this.techNodes = const <TechNodeModel>[],
  });

  final List<TechNodeModel> techNodes;

  @override
  ConsumerState<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends ConsumerState<ActionPanel> {
  bool _dialogoAtaqueAbierto = false;

  String _formatName(String id) {
    return id
        .split('_')
        .map(
          (word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _parseErrorDetail(DioException error, {String fallback = 'Acción no disponible'}) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail']?.toString().trim();
      if (detail != null && detail.isNotEmpty) return detail;
    }

    final text = data?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    return error.message ?? fallback;
  }

  Future<void> _refrescarEstadoPartida(WidgetRef ref) async {
    final partidaId = ref.read(webSocketProvider).currentPartidaId;
    if (partidaId == null) return;

    final response = await ref.read(dioProvider).get('/partidas/$partidaId/estado');
    if (response.data is! Map) return;

    ref.read(gameProvider.notifier).actualizarDesdeServidor(
          Map<String, dynamic>.from(response.data as Map),
        );
  }

  ButtonStyle _actionButtonStyle(bool enabled) {
    return ElevatedButton.styleFrom(
      elevation: enabled ? 3 : 0,
      backgroundColor: enabled ? const Color(0xFF3A2A16) : const Color(0xFF2A241C),
      foregroundColor: enabled
          ? AppTheme.primary
          : AppTheme.textSecondary.withValues(alpha: 0.65),
      disabledBackgroundColor: const Color(0xFF2A241C),
      disabledForegroundColor: AppTheme.textSecondary.withValues(alpha: 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.75)
              : AppTheme.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildGameDialog({
    required BuildContext context,
    required Widget child,
    double maxWidth = 380,
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
            border: Border.all(
              color: AppTheme.primary,
              width: 1.4,
            ),
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

  ButtonStyle _dialogPrimaryButtonStyle() {
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

  ButtonStyle _dialogSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primary,
      side: BorderSide(
        color: AppTheme.primary.withValues(alpha: 0.55),
        width: 1.1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  List<SpecialAttackModel> _ownedSpecialAttacks(GameState gameState, String username) {
    final ownedIds = <String>{
      ...(gameState.jugadores[username]?.tecnologiasCompradas ?? const <String>[]),
    };
    final attacks = <SpecialAttackModel>[];

    for (final node in widget.techNodes) {
      if (!ownedIds.contains(node.id)) continue;
      final attack = SpecialAttackModel.fromTechNode(node);
      if (attack != null) {
        attacks.add(attack);
      }
    }

    return attacks;
  }

  List<_SpecialAttackTargetOption> _buildTargetOptions({
    required GameState gameState,
    required String username,
    required String origin,
    required SpecialAttackModel attack,
  }) {
    if (!attack.requiresTarget) return const <_SpecialAttackTargetOption>[];

    if (attack.targetType == SpecialAttackTargetType.player) {
      final options = <_SpecialAttackTargetOption>[];
      for (final playerName in gameState.jugadores.keys) {
        if (!_matchesPlayerTargetSide(
          playerName: playerName,
          username: username,
          side: attack.targetSide,
        )) {
          continue;
        }

        options.add(
          _SpecialAttackTargetOption(
            id: playerName,
            label: playerName == username ? '$playerName (tú)' : playerName,
            subtitle: 'Jugador objetivo',
          ),
        );
      }
      return options;
    }

    final graphState = ref.read(graphServiceProvider);
    final graph = graphState is AsyncData ? graphState.value : null;
    Set<String>? idsEnRango;

    if (attack.maxRange != null && attack.maxRange! > 0 && graph != null) {
      idsEnRango = graph.obtenerComarcasEnRango(origin, attack.maxRange!);

      final minRange = attack.minRange ?? 1;
      if (minRange > 1) {
        final idsDemasiadoCerca = graph.obtenerComarcasEnRango(origin, minRange - 1);
        idsEnRango = idsEnRango.difference(idsDemasiadoCerca);
      }
    }

    final ownerOrigen = gameState.mapa[origin]?.ownerId ?? username;
    final options = <_SpecialAttackTargetOption>[];

    for (final entry in gameState.mapa.entries) {
      final territoryId = entry.key;
      final territory = entry.value;

      if (attack.targetSide == SpecialAttackTargetSide.self && territoryId != origin) {
        continue;
      }
      if (attack.targetSide != SpecialAttackTargetSide.self && territoryId == origin) {
        continue;
      }
      if (idsEnRango != null && !idsEnRango.contains(territoryId) && territoryId != origin) {
        continue;
      }
      if (!_matchesTerritoryTargetSide(
        territoryOwner: territory.ownerId,
        ownerOrigen: ownerOrigen,
        side: attack.targetSide,
      )) {
        continue;
      }

      final ownerLabel = territory.ownerId.isEmpty ? 'Sin dueño' : territory.ownerId;
      options.add(
        _SpecialAttackTargetOption(
          id: territoryId,
          label: _formatName(territoryId),
          subtitle: '$ownerLabel · ${territory.units} tropas',
        ),
      );
    }

    return options;
  }

  bool _matchesPlayerTargetSide({
    required String playerName,
    required String username,
    required SpecialAttackTargetSide side,
  }) {
    switch (side) {
      case SpecialAttackTargetSide.self:
        return playerName == username;
      case SpecialAttackTargetSide.ally:
        return playerName == username;
      case SpecialAttackTargetSide.any:
        return true;
      case SpecialAttackTargetSide.enemy:
        return playerName != username;
    }
  }

  bool _matchesTerritoryTargetSide({
    required String territoryOwner,
    required String ownerOrigen,
    required SpecialAttackTargetSide side,
  }) {
    switch (side) {
      case SpecialAttackTargetSide.self:
        return territoryOwner == ownerOrigen;
      case SpecialAttackTargetSide.ally:
        return territoryOwner == ownerOrigen;
      case SpecialAttackTargetSide.any:
        return true;
      case SpecialAttackTargetSide.enemy:
        return territoryOwner != ownerOrigen;
    }
  }

  String _specialAttackHint(SpecialAttackModel attack) {
    final parts = <String>[];

    if (attack.minRange != null && attack.maxRange != null) {
      if (attack.minRange == attack.maxRange) {
        parts.add('Alcance exacto: ${attack.maxRange}');
      } else {
        parts.add('Alcance: ${attack.minRange}-${attack.maxRange}');
      }
    } else if (attack.maxRange != null) {
      parts.add('Alcance máximo: ${attack.maxRange}');
    }

    switch (attack.targetType) {
      case SpecialAttackTargetType.territory:
        parts.add('Objetivo: ${_targetSideLabel(attack.targetSide, territory: true)}');
        break;
      case SpecialAttackTargetType.player:
        parts.add('Objetivo: ${_targetSideLabel(attack.targetSide, territory: false)}');
        break;
    }

    return parts.join(' · ');
  }

  String _targetSideLabel(SpecialAttackTargetSide side, {required bool territory}) {
    switch (side) {
      case SpecialAttackTargetSide.self:
        return territory ? 'territorio propio' : 'tú';
      case SpecialAttackTargetSide.ally:
        return territory ? 'territorio aliado' : 'jugador aliado';
      case SpecialAttackTargetSide.any:
        return territory ? 'cualquier territorio' : 'cualquier jugador';
      case SpecialAttackTargetSide.enemy:
        return territory ? 'territorio enemigo' : 'jugador enemigo';
    }
  }

  String _resolveAttackEndpoint(int partidaId, SpecialAttackModel attack) {
    final path = attack.endpointPath.trim();
    if (path.isEmpty) {
      return '/partidas/$partidaId/ataque_especial';
    }
    if (path.contains('{partidaId}')) {
      return path.replaceAll('{partidaId}', '$partidaId');
    }
    if (path.startsWith('/')) {
      return path;
    }
    return '/partidas/$partidaId/$path';
  }

  Map<String, dynamic> _buildSpecialAttackPayload({
    required SpecialAttackModel attack,
    required String origin,
    String? targetId,
  }) {
    final payload = <String, dynamic>{};
    final attackField =
        attack.payloadMapping['attack'] ?? attack.payloadMapping['ataque'] ?? 'ataque_id';
    final originField =
        attack.payloadMapping['origin'] ?? attack.payloadMapping['origen'] ?? 'territorio_origen_id';

    payload[attackField] = attack.id;

    if (attack.requiresOrigin) {
      payload[originField] = origin;
    }

    if (attack.requiresTarget && targetId != null && targetId.isNotEmpty) {
      payload[attack.targetFieldName()] = targetId;
    }

    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? '';
    final origenSeleccionado = gameState.origenSeleccionado;
    final esMiTurno = username.isNotEmpty && gameState.turnoDe == username;
    final puedeAtacar = gameState.faseActual == 'ataque_convencional' && esMiTurno;
    final puedeFortificar = gameState.faseActual == 'fortificacion' && esMiTurno;
    final ataquesEspeciales = _ownedSpecialAttacks(gameState, username);
    final faseAtaqueEspecial = gameState.faseActual == 'ataque_especial';
    final puedeAbrirAtaqueEspecial =
        faseAtaqueEspecial && esMiTurno && origenSeleccionado != null && ataquesEspeciales.isNotEmpty;
    final catalogoTieneAtaquesEspeciales = widget.techNodes.any(
      (node) => SpecialAttackModel.fromTechNode(node) != null,
    );

    ref.listen<GameState>(gameProvider, (previous, next) {
      final destinoAcabaDeSeleccionarse =
          (previous?.destinoSeleccionado == null) && next.destinoSeleccionado != null;

      if (!destinoAcabaDeSeleccionarse || _dialogoAtaqueAbierto) return;

      final origen = next.origenSeleccionado;
      final destino = next.destinoSeleccionado;
      if (origen == null || destino == null) return;

      final ownerOrigen = next.mapa[origen]?.ownerId;
      final ownerDestino = next.mapa[destino]?.ownerId;
      if (next.faseActual == 'ataque_convencional' &&
          ownerOrigen != null &&
          ownerDestino != null &&
          ownerOrigen == ownerDestino) {
        ref.read(gameProvider.notifier).cancelarAtaque();
        return;
      }

      _dialogoAtaqueAbierto = true;

      if (next.faseActual == 'ataque_convencional') {
        _mostrarDialogoAtaque(context, ref, origen, destino)
            .whenComplete(() => _dialogoAtaqueAbierto = false);
      } else if (next.faseActual == 'fortificacion') {
        final tropasOrigen = next.mapa[origen]?.units ?? 0;
        _mostrarDialogoFortificacion(context, ref, origen, destino, tropasOrigen)
            .whenComplete(() => _dialogoAtaqueAbierto = false);
      } else {
        _dialogoAtaqueAbierto = false;
      }
    });

    final bool isVisible =
        origenSeleccionado != null && gameState.faseActual.toLowerCase() != 'gestion';
    final territoryData =
        origenSeleccionado != null ? gameState.mapa[origenSeleccionado] : null;
    final owner = territoryData?.ownerId ?? 'Neutral';
    final units = territoryData?.units ?? 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: isVisible ? 12 : -290,
      top: MediaQuery.of(context).size.height * 0.14,
      width: 270,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        origenSeleccionado != null ? _formatName(origenSeleccionado) : '',
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
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        if (origenSeleccionado != null) {
                          ref.read(gameProvider.notifier).seleccionarComarca(
                                origenSeleccionado,
                                jugadorLocalId: username,
                              );
                        }
                      },
                    ),
                  ],
                ),
                Divider(
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  height: 18,
                  thickness: 1,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                            const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                owner,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$units',
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (gameState.esperandoDestino) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.ads_click_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                puedeAtacar
                                    ? 'Selecciona un territorio enemigo'
                                    : 'Selecciona un territorio aliado',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          puedeAtacar
                              ? 'Pulsa sobre una comarca adyacente para iniciar el ataque.'
                              : 'Pulsa sobre una comarca válida para mover tropas.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => ref.read(gameProvider.notifier).cancelarAtaque(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text(
                              'Cancelar selección',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.55),
                                width: 1.1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!gameState.esperandoDestino) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: _actionButtonStyle(puedeAtacar),
                        onPressed: puedeAtacar
                            ? () => ref.read(gameProvider.notifier).prepararAtaque()
                            : null,
                        icon: const Icon(Icons.sports_kabaddi_rounded, size: 20),
                        label: const Text(
                          'Atacar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _actionButtonStyle(puedeAbrirAtaqueEspecial),
                        onPressed: puedeAbrirAtaqueEspecial
                            ? () => _mostrarDialogoAtaqueEspecial(
                                  context: context,
                                  ref: ref,
                                  origen: origenSeleccionado,
                                  username: username,
                                  gameState: gameState,
                                  attacks: ataquesEspeciales,
                                )
                            : null,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: const Text(
                          'Ataque especial',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (faseAtaqueEspecial) ...[
                        const SizedBox(height: 8),
                        Text(
                          !catalogoTieneAtaquesEspeciales
                              ? 'El catálogo aún no trae ataques especiales configurados por backend.'
                              : ataquesEspeciales.isEmpty
                                  ? 'No tienes ataques especiales comprados para esta fase.'
                                  : 'Selecciona el ataque desde el botón y el frontend validará alcance si el backend lo informa.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _actionButtonStyle(
                          gameState.faseActual == 'refuerzo' &&
                              esMiTurno &&
                              origenSeleccionado != null,
                        ),
                        onPressed: gameState.faseActual == 'refuerzo' &&
                                esMiTurno &&
                                origenSeleccionado != null
                            ? () => _mostrarDialogoRefuerzo(context, ref, origenSeleccionado)
                            : null,
                        icon: const Icon(Icons.add_box_rounded, size: 20),
                        label: const Text(
                          'Reforzar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: _actionButtonStyle(
                          puedeFortificar && origenSeleccionado != null && units > 1,
                        ),
                        onPressed: puedeFortificar && origenSeleccionado != null && units > 1
                            ? () => ref.read(gameProvider.notifier).prepararAtaque()
                            : null,
                        icon: const Icon(Icons.fort_rounded, size: 20),
                        label: const Text(
                          'Mover',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAtaque(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _buildGameDialog(
          context: context,
          maxWidth: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atacar ${_formatName(destino)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '¿Confirmas el ataque de ${_formatName(origen)} a ${_formatName(destino)}?\n\n'
                'Todas tus tropas lucharán hasta conquistar o quedarse con 1.',
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(gameProvider.notifier).cancelarAtaque();
                        Navigator.of(dialogContext).pop();
                      },
                      style: _dialogSecondaryButtonStyle(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _enviarAtaquePorHttp(
                          context: context,
                          dialogContext: dialogContext,
                          ref: ref,
                          origen: origen,
                          destino: destino,
                        );
                      },
                      style: _dialogPrimaryButtonStyle(),
                      child: const Text(
                        '¡Atacar!',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarDialogoAtaqueEspecial({
    required BuildContext context,
    required WidgetRef ref,
    required String origen,
    required String username,
    required GameState gameState,
    required List<SpecialAttackModel> attacks,
  }) async {
    if (attacks.isEmpty) return;

    SpecialAttackModel selectedAttack = attacks.first;
    String? selectedTargetId;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final targets = _buildTargetOptions(
              gameState: gameState,
              username: username,
              origin: origen,
              attack: selectedAttack,
            );

            if (selectedAttack.requiresTarget) {
              final targetStillValid = targets.any((item) => item.id == selectedTargetId);
              if (!targetStillValid) {
                selectedTargetId = targets.isNotEmpty ? targets.first.id : null;
              }
            } else {
              selectedTargetId = null;
            }

            final puedeLanzarse =
                !selectedAttack.requiresTarget || selectedTargetId != null;

            return _buildGameDialog(
              context: context,
              maxWidth: 420,
              child: Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Ataque especial desde ${_formatName(origen)}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SpecialAttackModel>(
                      value: selectedAttack,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tecnología',
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Theme.of(context).cardColor,
                      items: attacks
                          .map(
                            (attack) => DropdownMenuItem<SpecialAttackModel>(
                              value: attack,
                              child: Text(
                                attack.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedAttack = value;
                          selectedTargetId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedAttack.description,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _specialAttackHint(selectedAttack),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (selectedAttack.requiresTarget)
                      if (targets.isEmpty)
                        const Text(
                          'No hay objetivos válidos con la información actual. Si el backend permite más casos, ajusta el metadato del catálogo.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedTargetId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: selectedAttack.targetType == SpecialAttackTargetType.player
                                ? 'Jugador objetivo'
                                : 'Territorio objetivo',
                            border: const OutlineInputBorder(),
                          ),
                          dropdownColor: Theme.of(context).cardColor,
                          items: targets
                              .map(
                                (target) => DropdownMenuItem<String>(
                                  value: target.id,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(target.label, overflow: TextOverflow.ellipsis),
                                      Text(
                                        target.subtitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTargetId = value;
                            });
                          },
                        ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: _dialogSecondaryButtonStyle(),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: puedeLanzarse
                                ? () => _enviarAtaqueEspecial(
                                      context: context,
                                      dialogContext: dialogContext,
                                      ref: ref,
                                      origin: origen,
                                      attack: selectedAttack,
                                      targetId: selectedTargetId,
                                    )
                                : null,
                            style: _dialogPrimaryButtonStyle(),
                            child: const Text(
                              'Lanzar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _mostrarDialogoFortificacion(
    BuildContext context,
    WidgetRef ref,
    String origen,
    String destino,
    int tropasOrigen,
  ) async {
    final maxMover = (tropasOrigen - 1).clamp(1, tropasOrigen - 1);
    int tropasAMover = maxMover;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return _buildGameDialog(
              context: context,
              maxWidth: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mover tropas a ${_formatName(destino)}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'De ${_formatName(origen)} → ${_formatName(destino)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '$tropasAMover',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 34),
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
                          onChanged: (v) => setDialogState(() => tropasAMover = v.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 34),
                        color: AppTheme.primary,
                        onPressed: tropasAMover < maxMover
                            ? () => setDialogState(() => tropasAMover++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Disponibles: $tropasOrigen (mín. 1 se queda en origen)',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(gameProvider.notifier).cancelarAtaque();
                            Navigator.of(dialogContext).pop();
                          },
                          style: _dialogSecondaryButtonStyle(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final partidaId = ref.read(webSocketProvider).currentPartidaId;
                            if (partidaId == null) return;

                            try {
                              final dio = ref.read(dioProvider);
                              await dio.post(
                                '/partidas/$partidaId/fortificar',
                                data: {
                                  'origen': origen,
                                  'destino': destino,
                                  'tropas': tropasAMover,
                                },
                              );
                              await _refrescarEstadoPartida(ref);
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              ref.read(gameProvider.notifier).cancelarAtaque();
                            } on DioException catch (e) {
                              final detalle = _parseErrorDetail(
                                e,
                                fallback: 'Error al fortificar',
                              );
                              debugPrint('ERROR fortificacion: $detalle');
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $detalle')),
                              );
                            }
                          },
                          style: _dialogPrimaryButtonStyle(),
                          child: const Text(
                            'Mover',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoRefuerzo(
    BuildContext context,
    WidgetRef ref,
    String territorio,
  ) async {
    final username = ref.read(authProvider).user?.username ?? '';
    final reserva = ref.read(gameProvider).jugadores[username]?.tropasReserva ?? 0;

    if (reserva <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes tropas en reserva.')),
      );
      return;
    }

    int tropasAEnviar = 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return _buildGameDialog(
              context: context,
              maxWidth: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reforzar ${_formatName(territorio)}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reserva disponible: $reserva',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '$tropasAEnviar',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 34),
                        color: AppTheme.primary,
                        onPressed: tropasAEnviar > 1
                            ? () => setDialogState(() => tropasAEnviar--)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tropasAEnviar.toDouble(),
                          min: 1,
                          max: reserva.toDouble(),
                          onChanged: (v) => setDialogState(() => tropasAEnviar = v.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 34),
                        color: AppTheme.primary,
                        onPressed: tropasAEnviar < reserva
                            ? () => setDialogState(() => tropasAEnviar++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(gameProvider.notifier).cancelarAtaque();
                            Navigator.of(dialogContext).pop();
                          },
                          style: _dialogSecondaryButtonStyle(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final partidaId = ref.read(webSocketProvider).currentPartidaId;
                            if (partidaId == null) return;

                            try {
                              final dio = ref.read(dioProvider);
                              await dio.post(
                                '/partidas/$partidaId/colocar_tropas',
                                data: {
                                  'territorio_id': territorio,
                                  'tropas': tropasAEnviar,
                                },
                              );
                              await _refrescarEstadoPartida(ref);

                              final estadoActual = ref.read(gameProvider);
                              final faseActual = estadoActual.faseActual.trim().toLowerCase();
                              final tropasReservaRestantes =
                                  estadoActual.jugadores[username]?.tropasReserva ?? 0;

                              if (faseActual == 'refuerzo' && tropasReservaRestantes <= 0) {
                                await dio.post('/partidas/$partidaId/pasar_fase');
                                await _refrescarEstadoPartida(ref);
                                ref.read(gameProvider.notifier).reiniciarTemporizador();
                              }

                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                            } on DioException catch (e) {
                              final detalle = _parseErrorDetail(
                                e,
                                fallback: 'Error al reforzar',
                              );
                              debugPrint('ERROR refuerzo: $detalle');
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $detalle')),
                              );
                            }
                          },
                          style: _dialogPrimaryButtonStyle(),
                          child: const Text(
                            'Reforzar',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _enviarAtaquePorHttp({
    required BuildContext context,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required String origen,
    required String destino,
  }) async {
    final dio = ref.read(dioProvider);
    final partidaId = ref.read(webSocketProvider).currentPartidaId;

    if (partidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no hay partida activa conectada.')),
      );
      return;
    }

    try {
      ref.read(gameProvider.notifier).registrarAtaquePendiente(
            origen: origen,
            destino: destino,
          );

      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      ref.read(gameProvider.notifier).limpiarSeleccionCombate();

      await dio.post(
        '/partidas/$partidaId/ataque',
        data: {
          'territorio_origen_id': origen,
          'territorio_destino_id': destino,
        },
      );
    } on DioException catch (e) {
      ref.read(gameProvider.notifier).limpiarAtaquePendiente();
      final detalle = _parseErrorDetail(
        e,
        fallback: 'No se pudo ejecutar el ataque',
      );
      debugPrint('ERROR ATAQUE ${e.response?.statusCode}: $detalle');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${e.response?.statusCode}: $detalle')),
      );
    }
  }

  Future<void> _enviarAtaqueEspecial({
    required BuildContext context,
    required BuildContext dialogContext,
    required WidgetRef ref,
    required String origin,
    required SpecialAttackModel attack,
    required String? targetId,
  }) async {
    final partidaId = ref.read(webSocketProvider).currentPartidaId;
    if (partidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no hay partida activa conectada.')),
      );
      return;
    }

    final dio = ref.read(dioProvider);
    final endpoint = _resolveAttackEndpoint(partidaId, attack);
    final payload = _buildSpecialAttackPayload(
      attack: attack,
      origin: origin,
      targetId: targetId,
    );

    try {
      switch (attack.method) {
        case 'GET':
          await dio.get(endpoint, queryParameters: payload);
          break;
        case 'PUT':
          await dio.put(endpoint, data: payload);
          break;
        case 'PATCH':
          await dio.patch(endpoint, data: payload);
          break;
        case 'DELETE':
          await dio.delete(endpoint, data: payload);
          break;
        default:
          await dio.post(endpoint, data: payload);
          break;
      }

      await _refrescarEstadoPartida(ref);

      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF12161E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.primary, width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡${attack.name} lanzado con éxito sobre el objetivo!',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on DioException catch (e) {
      final detalle = _parseErrorDetail(
        e,
        fallback: 'No se pudo lanzar el ataque especial',
      );
      debugPrint('ERROR ATAQUE ESPECIAL ${e.response?.statusCode}: $detalle');

      if (!dialogContext.mounted) return;
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
}

class _SpecialAttackTargetOption {
  final String id;
  final String label;
  final String subtitle;

  const _SpecialAttackTargetOption({
    required this.id,
    required this.label,
    required this.subtitle,
  });
}
