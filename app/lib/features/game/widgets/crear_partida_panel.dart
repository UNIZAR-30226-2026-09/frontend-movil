import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/lobby_info_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/jugador_partida_model.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_close_button.dart';

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
      final usuarioActual = ref.read(authProvider).user?.username;
      ref.read(lobbyInfoProvider.notifier).setFromCreatedMatch(
        partidaId: match.id,
        creador: usuarioActual ?? '',
        codigoInvitacion: match.codigoInvitacion,
        maxPlayers: match.configMaxPlayers,
        visibility: match.configVisibility,
        timerSeconds: match.configTimerSeconds,
        jugadoresEnSala: [
          JugadorPartidaModel(
            usuarioId: usuarioActual ?? '',
            partidaId: match.id,
            turno: 0,
            estadoJugador: 'vivo',
          ),
        ],
      );

      widget.onClose();
      context.push(AppRoutes.lobbyPath(match.id));
    } else {
      // Pasamos del mensaje del servidor y ponemos el nuestro que se entiende mejor
      final errorMessage = 'Error al crear partida, ya tienes una partida activa';

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
                  errorMessage,
                  style: const TextStyle(color: Color(0xFFE89090), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
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
            color: AppTheme.panelOverlay.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderGold,
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
                        color: AppTheme.borderGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppCloseButton(
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.borderGold,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildConfigRow(
                        label: 'Max. Jugadores',
                        child: DropdownButtonFormField<int>(
                          value: _maxPlayers,
                          dropdownColor: AppTheme.surface,
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
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w600,
                          ),
                          iconEnabledColor: AppTheme.primary,
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
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w600,
                          ),
                          iconEnabledColor: AppTheme.primary,
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
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w600,
                          ),
                          iconEnabledColor: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      _CreateMatchButton(
                        isLoading: matchmakingState.isCreating,
                        onPressed: _createMatch,
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
    );
  }
}

class _CreateMatchButton extends StatefulWidget {
  const _CreateMatchButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_CreateMatchButton> createState() => _CreateMatchButtonState();
}

class _CreateMatchButtonState extends State<_CreateMatchButton> {
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
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isLoading ? AppTheme.disabled : backgroundColor,
            borderRadius: BorderRadius.circular(12),
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
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.bg,
                  ),
                )
              : const Text(
                  'CREAR PARTIDA',
                  style: TextStyle(
                    color: AppTheme.bg,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}