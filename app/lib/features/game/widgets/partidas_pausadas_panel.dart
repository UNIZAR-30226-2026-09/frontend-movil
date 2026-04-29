import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../models/partida_publica_model.dart';
import '../providers/lobby_info_provider.dart';
import '../providers/matchmaking_provider.dart';

class PartidasPausadasPanel extends ConsumerStatefulWidget {
  const PartidasPausadasPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<PartidasPausadasPanel> createState() =>
      _PartidasPausadasPanelState();
}

class _PartidasPausadasPanelState
    extends ConsumerState<PartidasPausadasPanel> {
  bool _cargando = true;
  PublicMatchModel? _partida;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await ref
          .read(matchmakingServiceProvider)
          .getPartidasPausadas();
      if (!mounted) return;
      setState(() {
        _partida = lista.isNotEmpty ? lista.first : null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo comprobar tu partida pausada.';
        _cargando = false;
      });
    }
  }

  void _entrar(PublicMatchModel partida) {
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 320,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF252530).withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC5A059),
              width: 1.2,
            ),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PARTIDA PAUSADA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8C6D3F),
                      width: 1,
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFA0A0B0),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_partida == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No tienes ninguna partida pausada actualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFA0A0B0),
            ),
          ),
        ),
      );
    }

    final partida = _partida!;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF252530),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC5A059),
            width: 1,
          ),
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
              onPressed: () => _entrar(partida),
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
