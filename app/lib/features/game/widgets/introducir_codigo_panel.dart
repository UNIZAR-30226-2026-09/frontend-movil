import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../providers/matchmaking_provider.dart';

class IntroducirCodigoPanel extends ConsumerStatefulWidget {
  const IntroducirCodigoPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<IntroducirCodigoPanel> createState() =>
      _IntroducirCodigoPanelState();
}

class _IntroducirCodigoPanelState
    extends ConsumerState<IntroducirCodigoPanel> {
  final TextEditingController _codigoController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinByCode() async {
    final codigo = _codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un código de partida'),
        ),
      );
      return;
    }

    final joinResponse = await ref.read(matchmakingProvider.notifier).joinMatch(codigo);

    if (!mounted) return;

    if (joinResponse != null && joinResponse.jugadoresEnSala.isNotEmpty) {
      final partidaId = joinResponse.jugadoresEnSala.first.partidaId;

      widget.onClose();
      context.push(AppRoutes.lobbyPath(partidaId));
    } else {
      final errorMessage = ref.read(matchmakingProvider).errorMessage ??
          'No se pudo unir a la partida';

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
                      'INTRODUCIR CÓDIGO',
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8C6D3F),
                      width: 1,
                    ),
                  ),
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
                      TextFormField(
                        controller: _codigoController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ejemplo: 5RH8AQ',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF252530),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF8C6D3F),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFC5A059),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Introduce el código de una partida privada o pública para unirte directamente.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFA0A0B0),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: matchmakingState.isJoining
                              ? null
                              : _handleJoinByCode,
                          child: matchmakingState.isJoining
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('UNIRSE A LA PARTIDA'),
                        ),
                      ),
                    ],
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