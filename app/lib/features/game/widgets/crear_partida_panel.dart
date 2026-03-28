import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../providers/matchmaking_provider.dart';

class CrearPartidaPanel extends ConsumerStatefulWidget {
  const CrearPartidaPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<CrearPartidaPanel> createState() => _CrearPartidaPanelState();
}

class _CrearPartidaPanelState extends ConsumerState<CrearPartidaPanel> {
  int _maxPlayers = 4;
  String _visibility = 'publica';
  int _timerSeconds = 60;

  Future<void> _createMatch() async {
    final match = await ref.read(matchmakingProvider.notifier).createMatch(
          maxPlayers: _maxPlayers,
          visibility: _visibility,
          timerSeconds: _timerSeconds,
        );

    if (!mounted) return;

    if (match != null) {
      widget.onClose();
      context.push(AppRoutes.lobbyPath(match.id));
    } else {
      final errorMessage = ref.read(matchmakingProvider).errorMessage ??
          'No se pudo crear la partida';

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
          maxHeight: 430,
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
                      'CREAR PARTIDA',
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
                    children: [
                      _buildConfigRow(
                        label: 'Max. Jugadores',
                        child: DropdownButtonFormField<int>(
                          value: _maxPlayers,
                          dropdownColor: const Color(0xFF252530),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                            DropdownMenuItem(value: 4, child: Text('4')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _maxPlayers = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildConfigRow(
                        label: 'Visibilidad',
                        child: DropdownButtonFormField<String>(
                          value: _visibility,
                          dropdownColor: const Color(0xFF252530),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(
                              value: 'publica',
                              child: Text('Pública'),
                            ),
                            DropdownMenuItem(
                              value: 'privada',
                              child: Text('Privada'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildConfigRow(
                        label: 'Temporizador',
                        child: DropdownButtonFormField<int>(
                          value: _timerSeconds,
                          dropdownColor: const Color(0xFF252530),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 segundos')),
                            DropdownMenuItem(value: 60, child: Text('60 segundos')),
                            DropdownMenuItem(value: 90, child: Text('90 segundos')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _timerSeconds = value;
                              });
                            }
                          },
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              matchmakingState.isCreating ? null : _createMatch,
                          child: matchmakingState.isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('CREAR PARTIDA'),
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

  Widget _buildConfigRow({
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: child,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    );
  }
}