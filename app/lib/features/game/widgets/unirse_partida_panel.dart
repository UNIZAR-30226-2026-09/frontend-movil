import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../models/partida_publica_model.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_close_button.dart';

enum _Vista { partidasRapidas, enSuspenso, codigoDirecto }

class UnirsePartidaPanel extends ConsumerStatefulWidget {
  const UnirsePartidaPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<UnirsePartidaPanel> createState() => _UnirsePartidaPanelState();
}

class _UnirsePartidaPanelState extends ConsumerState<UnirsePartidaPanel> {
  _Vista _vistaActual = _Vista.partidasRapidas;

  // ── Vista 1: código directo ──────────────────────────────────────────────
  final TextEditingController _codigoController = TextEditingController();

  // ── Vista 2: partida pausada ─────────────────────────────────────────────
  bool _cargandoPausada = false;
  List<PublicMatchModel>? _partidas;
  String? _errorPausada;
  bool _pausadaCargada = false;

  // ────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchmakingProvider.notifier).loadMatches();
    });
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  // ── Cambiar pestaña ──────────────────────────────────────────────────────
  void _cambiarVista(_Vista vista) {
    setState(() => _vistaActual = vista);
    if (vista == _Vista.enSuspenso && !_pausadaCargada) {
      _cargarPausada();
    }
  }

  // ── Cargar partida pausada ───────────────────────────────────────────────
  Future<void> _cargarPausada() async {
    setState(() {
      _cargandoPausada = true;
      _errorPausada = null;
    });

    try {
      final lista = await ref
          .read(matchmakingServiceProvider)
          .getPartidasPausadas();
      if (!mounted) return;
      setState(() {
        _partidas = lista;
        _cargandoPausada = false;
        _pausadaCargada = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPausada = 'No se pudo comprobar tus partidas pausadas.';
        _cargandoPausada = false;
        _pausadaCargada = true;
      });
    }
  }

  // ── Unirse por código ────────────────────────────────────────────────────
  Future<void> _joinMatch(String codigo) async {
    final codigoFinal = codigo.trim().toUpperCase();
    if (codigoFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un código de partida')),
      );
      return;
    }

    final joinResponse = await ref
        .read(matchmakingProvider.notifier)
        .joinMatch(codigoFinal);

    if (!mounted) return;

    if (joinResponse != null && joinResponse.jugadoresEnSala.isNotEmpty) {
      final partidaId = joinResponse.jugadoresEnSala.first.partidaId;

      ref
          .read(lobbyInfoProvider.notifier)
          .setFromJoinResponse(
            partidaId: partidaId,
            creador: joinResponse.creador,
            jugadoresEnSala: joinResponse.jugadoresEnSala,
            codigoInvitacion: codigoFinal,
          );

      widget.onClose();
      context.push(AppRoutes.lobbyPath(partidaId));
    } else {
      final errorMessage =
          ref.read(matchmakingProvider).errorMessage ??
          'No se pudo unir a la partida';
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
                  errorMessage,
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

  // ── Entrar a partida pausada ─────────────────────────────────────────────
  void _entrarPausada(PublicMatchModel partida) {
    ref
        .read(lobbyInfoProvider.notifier)
        .setFromPausedMatch(
          partidaId: partida.id,
          codigoInvitacion: partida.codigoInvitacion,
        );
    widget.onClose();
    context.push(AppRoutes.lobbyPath(partida.id), extra: {'esPausada': true});
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 450),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panelOverlay.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderGold, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera ────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'UNIRSE A PARTIDA',
                      style: TextStyle(
                        color: AppTheme.borderGold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppCloseButton(onPressed: widget.onClose),
                ],
              ),
              const SizedBox(height: 14),

              // ── Selector de pestaña ─────────────────────────────────────
              _TabSelector(vistaActual: _vistaActual, onCambiar: _cambiarVista),
              const SizedBox(height: 14),

              // ── Contenido ───────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGold, width: 1),
                  ),
                  child: switch (_vistaActual) {
                    _Vista.partidasRapidas => _VistaPartidasRapidas(
                      onJoinMatch: _joinMatch,
                    ),
                    _Vista.enSuspenso => _VistaPausada(
                      cargando: _cargandoPausada,
                      partidas: _partidas,
                      error: _errorPausada,
                      onReintentar: _cargarPausada,
                      onEntrar: _entrarPausada,
                    ),
                    _Vista.codigoDirecto => _VistaCodigo(
                      codigoController: _codigoController,
                      onJoinMatch: _joinMatch,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Selector de pestañas
// ════════════════════════════════════════════════════════════════════════════
class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.vistaActual, required this.onCambiar});

  final _Vista vistaActual;
  final ValueChanged<_Vista> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderBronze, width: 1),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'RÁPIDAS',
            isActive: vistaActual == _Vista.partidasRapidas,
            onTap: () => onCambiar(_Vista.partidasRapidas),
            isFirst: true,
          ),
          _TabButton(
            label: 'EN SUSPENSO',
            isActive: vistaActual == _Vista.enSuspenso,
            onTap: () => onCambiar(_Vista.enSuspenso),
            isFirst: false,
            isLast: false,
          ),
          _TabButton(
            label: 'CÓDIGO',
            isActive: vistaActual == _Vista.codigoDirecto,
            onTap: () => onCambiar(_Vista.codigoDirecto),
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isFirst,
    this.isLast = false,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.borderGold.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(9) : Radius.zero,
              right: isLast ? const Radius.circular(9) : Radius.zero,
            ),
            border: isActive
                ? Border.all(color: AppTheme.borderGold, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.borderGold : AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Vista 1 – Partidas rápidas públicas
// ════════════════════════════════════════════════════════════════════════════
class _VistaPartidasRapidas extends ConsumerWidget {
  const _VistaPartidasRapidas({required this.onJoinMatch});

  final Future<void> Function(String codigo) onJoinMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchmakingProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.borderGold),
      );
    }

    if (state.errorMessage != null && state.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () =>
                    ref.read(matchmakingProvider.notifier).loadMatches(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(matchmakingProvider.notifier).refreshMatches(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Center(
              child: Text(
                'No hay partidas rápidas disponibles ahora mismo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(matchmakingProvider.notifier).refreshMatches(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final partida = state.matches[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderGold, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Código: ${partida.codigoInvitacion}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estado: ${partida.estado}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jugadores: ${partida.configMaxPlayers} máx.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _JoinMatchButton(
                  text: 'ENTRAR',
                  compact: true,
                  isLoading: state.isJoining,
                  onPressed: () => onJoinMatch(partida.codigoInvitacion),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Vista 2 – Solo código directo
// ════════════════════════════════════════════════════════════════════════════
class _VistaCodigo extends ConsumerWidget {
  const _VistaCodigo({
    required this.codigoController,
    required this.onJoinMatch,
  });

  final TextEditingController codigoController;
  final Future<void> Function(String codigo) onJoinMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchmakingProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de invitación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: codigoController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Ejemplo: 5RH8AQ',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.borderBronze,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.borderGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Introduce el código de una partida privada o pública para unirte directamente.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          _JoinMatchButton(
            text: 'INFILTRARSE',
            isLoading: state.isJoining,
            onPressed: () => onJoinMatch(codigoController.text),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Vista 2 – Partida en suspenso
// ════════════════════════════════════════════════════════════════════════════
class _VistaPausada extends StatelessWidget {
  const _VistaPausada({
    required this.cargando,
    required this.partidas,
    required this.error,
    required this.onReintentar,
    required this.onEntrar,
  });

  final bool cargando;
  final List<PublicMatchModel>? partidas;
  final String? error;
  final VoidCallback onReintentar;
  final ValueChanged<PublicMatchModel> onEntrar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.borderGoldVivo),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (partidas == null || partidas!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No tienes ninguna partida pausada actualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: partidas!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final partida = partidas![index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGold, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.pause_circle_outline_rounded, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Código: ${partida.codigoInvitacion}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jugadores: ${partida.configMaxPlayers} máx.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Visibilidad: ${partida.configVisibility}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _JoinMatchButton(
                text: 'ENTRAR',
                compact: true,
                onPressed: () => onEntrar(partida),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinMatchButton extends StatefulWidget {
  const _JoinMatchButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.compact = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool compact;

  @override
  State<_JoinMatchButton> createState() => _JoinMatchButtonState();
}

class _JoinMatchButtonState extends State<_JoinMatchButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isLoading) return;
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.primary;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: widget.compact ? null : double.infinity,
          height: widget.compact ? 38 : 46,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isLoading ? AppTheme.disabled : backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.22 : 0.32),
                blurRadius: _pressed ? 8 : 10,
                offset: Offset(0, _pressed ? 3 : 5),
              ),
            ],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.bg,
                  ),
                )
              : Text(
                  widget.text.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.bg,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
