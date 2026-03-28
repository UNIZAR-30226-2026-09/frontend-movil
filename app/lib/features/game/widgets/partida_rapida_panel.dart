import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../providers/matchmaking_provider.dart';

class PartidaRapidaPanel extends ConsumerStatefulWidget {
  const PartidaRapidaPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<PartidaRapidaPanel> createState() => _PartidaRapidaPanelState();
}

class _PartidaRapidaPanelState extends ConsumerState<PartidaRapidaPanel> {
  @override
  void initState(){
    super.initState();
    Future.microtask(() {
      ref.read(matchmakingProvider.notifier).loadMatches();
    });
  }

  Future<void> _joinMatch(String codigo) async {
    final success = await ref.read(matchmakingProvider.notifier).joinMatch(codigo);

    if(!mounted) return;

    if(success) {
      widget.onClose();
      context.push(AppRoutes.lobbyPath(84));
    } else {
      final errorMessage = ref.read(matchmakingProvider).errorMessage ?? 'No se pudo unir a la partida';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), 
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final matchmakingState = ref.watch(matchmakingProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 400,
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
                      'PARTIDAS PÚBLICAS',
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
                  child: _buildContent(matchmakingState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MatchmakingState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null && state.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFA0A0B0),
            ),
          ),
        ),
      );
    }

    if (state.matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(matchmakingProvider.notifier).refreshMatches(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No hay partidas públicas disponibles.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFA0A0B0),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(matchmakingProvider.notifier).refreshMatches(), 
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: state.matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final match = state.matches[index];

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: state.isJoining
                ? null
                : () {
                  print('CODIGO A UNIRSE: ${match.codigoInvitacion}');
                  _joinMatch(match.codigoInvitacion);
                  },
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
                  const Icon(Icons.public),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código: ${match.codigoInvitacion}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${match.estado}',
                          style: const TextStyle(
                            color: Color(0xFFA0A0B0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Máximo de jugadores: ${match.configMaxPlayers}',
                          style: const TextStyle(
                            color: Color(0xFFA0A0B0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  state.isJoining
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}