import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../models/partida_publica_model.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';

enum _Vista { codigoDirecto, enSuspenso }

class UnirsePartidaPanel extends ConsumerStatefulWidget {
  const UnirsePartidaPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<UnirsePartidaPanel> createState() => _UnirsePartidaPanelState();
}

class _UnirsePartidaPanelState extends ConsumerState<UnirsePartidaPanel> {
  _Vista _vistaActual = _Vista.codigoDirecto;

  // ── Vista 1: código directo ──────────────────────────────────────────────
  final TextEditingController _codigoController = TextEditingController();

  // ── Vista 2: partida pausada ─────────────────────────────────────────────
  bool _cargandoPausada = false;
  List<PublicMatchModel>? _partidas;
  String? _errorPausada;
  bool _pausadaCargada = false;

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
      final lista =
          await ref.read(matchmakingServiceProvider).getPartidasPausadas();
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

    final joinResponse =
        await ref.read(matchmakingProvider.notifier).joinMatch(codigoFinal);

    if (!mounted) return;

    if (joinResponse != null && joinResponse.jugadoresEnSala.isNotEmpty) {
      final partidaId = joinResponse.jugadoresEnSala.first.partidaId;

      ref.read(lobbyInfoProvider.notifier).setFromJoinResponse(
            partidaId: partidaId,
            creador: joinResponse.creador,
            jugadoresEnSala: joinResponse.jugadoresEnSala,
            codigoInvitacion: codigoFinal,
          );

      widget.onClose();
      context.push(AppRoutes.lobbyPath(partidaId));
    } else {
      final errorMessage = ref.read(matchmakingProvider).errorMessage ??
          'No se pudo unir a la partida';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // ── Entrar a partida pausada ─────────────────────────────────────────────
  void _entrarPausada(PublicMatchModel partida) {
    ref.read(lobbyInfoProvider.notifier).setFromPausedMatch(
          partidaId: partida.id,
          codigoInvitacion: partida.codigoInvitacion,
        );
    widget.onClose();
    context.push(
      AppRoutes.lobbyPath(partida.id),
      extra: {'esPausada': true},
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 450,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF252530).withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC5A059), width: 1.2),
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFC5A059), width: 1.1),
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Cerrar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Selector de pestaña ─────────────────────────────────────
              _TabSelector(
                vistaActual: _vistaActual,
                onCambiar: _cambiarVista,
              ),
              const SizedBox(height: 14),

              // ── Contenido ───────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF8C6D3F), width: 1),
                  ),
                  child: _vistaActual == _Vista.codigoDirecto
                      ? _VistaCodigo(
                          codigoController: _codigoController,
                          onJoinMatch: _joinMatch,
                        )
                      : _VistaPausada(
                          cargando: _cargandoPausada,
                          partidas: _partidas,
                          error: _errorPausada,
                          onReintentar: _cargarPausada,
                          onEntrar: _entrarPausada,
                        ),
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
  const _TabSelector({
    required this.vistaActual,
    required this.onCambiar,
  });

  final _Vista vistaActual;
  final ValueChanged<_Vista> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8C6D3F), width: 1),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'CÓDIGO DIRECTO',
            isActive: vistaActual == _Vista.codigoDirecto,
            onTap: () => onCambiar(_Vista.codigoDirecto),
            isFirst: true,
          ),
          _TabButton(
            label: 'EN SUSPENSO',
            isActive: vistaActual == _Vista.enSuspenso,
            onTap: () => onCambiar(_Vista.enSuspenso),
            isFirst: false,
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
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFC5A059).withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(9) : Radius.zero,
              right: !isFirst ? const Radius.circular(9) : Radius.zero,
            ),
            border: isActive
                ? Border.all(color: const Color(0xFFC5A059), width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? const Color(0xFFC5A059)
                  : const Color(0xFFA0A0B0),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Vista 1 – Solo código directo
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: codigoController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ejemplo: 5RH8AQ',
              hintStyle:
                  const TextStyle(color: Color(0xFF6A6A7A), fontSize: 14),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: const Color(0xFF252530),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF8C6D3F), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFC5A059), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Introduce el código de una partida privada o pública para unirte directamente.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFA0A0B0),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  state.isJoining ? null : () => onJoinMatch(codigoController.text),
              child: state.isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'INFILTRARSE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
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
      return const Center(child: CircularProgressIndicator());
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
                    fontSize: 15, color: Color(0xFFA0A0B0)),
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
            style: TextStyle(fontSize: 15, color: Color(0xFFA0A0B0)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: partidas!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final partida = partidas![index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF252530),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC5A059), width: 1),
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
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jugadores: ${partida.configMaxPlayers} máx.',
                      style: const TextStyle(color: Color(0xFFA0A0B0)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Visibilidad: ${partida.configVisibility}',
                      style: const TextStyle(color: Color(0xFFA0A0B0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => onEntrar(partida),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
