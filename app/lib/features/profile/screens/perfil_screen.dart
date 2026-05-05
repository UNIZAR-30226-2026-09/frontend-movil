import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/estadisticas_model.dart';
import '../providers/estadisticas_provider.dart';
import '../widgets/editar_perfil_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/perfil_estadisticas_panel.dart';
import '../../../shared/widgets/app_back_button.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _showEditProfile = false;
  bool _showEditProfileOverlay = false;

  void _openEditProfile() {
    setState(() {
      _showEditProfileOverlay = true;
      _showEditProfile = true;
    });
  }

  void _closeEditProfile() {
    setState(() {
      _showEditProfile = false;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _showEditProfileOverlay = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final estadisticasAsync = ref.watch(estadisticasProvider);
    final username = authState.user?.username ?? 'Jugador';
    final email = authState.user?.email ?? '';
    final avatar = authState.user?.avatar;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: AppBackButton(
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 750,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.borderGold,
                                          width: 1.2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 16,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 180,
                                            child: Column(
                                              children: [
                                                AppAvatar(
                                                  avatar: avatar,
                                                  radius: 42,
                                                  fallbackIcon: Icons.person,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Perfil de $username',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: AppTheme.borderGold,
                                                    fontSize: 22,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _PerfilInfoField(
                                                  label: 'Nombre de usuario',
                                                  value: username,
                                                ),
                                                const SizedBox(height: 12),
                                                _PerfilInfoField(
                                                  label: 'Correo de campo',
                                                  value: email,
                                                ),
                                                const SizedBox(height: 18),
                                                Row(
                                                  children: [
                                                    _ProfileActionButton(
                                                      text: 'Editar perfil',
                                                      variant: _ProfileActionButtonVariant.primary,
                                                      onPressed: _openEditProfile,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    _ProfileActionButton(
                                                      text: 'Cerrar sesión',
                                                      variant: _ProfileActionButtonVariant.danger,
                                                      onPressed: () async {
                                                        await ref.read(authProvider.notifier).logout();
                                                        if (context.mounted) {
                                                          context.go('/inicio');
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.borderGold,
                                          width: 1.2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 16,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: _buildStatsContainer(
                                        estadisticasAsync,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showEditProfileOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeEditProfile,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _showEditProfile ? 1 : 0,
                  child: Container(color: Colors.black54),
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.96,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showEditProfile
                ? EditarPerfilPanel(
                    key: const ValueKey('editProfileOpen'),
                    onClose: _closeEditProfile,
                  )
                : const SizedBox.shrink(key: ValueKey('editProfileClosed')),
          ),
        ],
      ),
    );
  }

  

  Widget _buildStatsLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppTheme.borderGoldVivo,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsError(Object error, StackTrace _) {
    final mensaje = error.toString().replaceFirst('Exception: ', '');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bg.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 28,
            ),
            const SizedBox(height: 10),
            const Text(
              'No pudimos cargar las estadísticas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.refresh(estadisticasProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContainer(AsyncValue<EstadisticasModel> estadisticasAsync) {
    return estadisticasAsync.when(
      data: (estadisticas) {
        return PerfilEstadisticasPanel(
          stats: _buildStats(estadisticas),
        );
      },
      loading: _buildStatsLoading,
      error: _buildStatsError,
    );
  }

  

  List<PerfilEstadisticasItem> _buildStats(EstadisticasModel estadisticas) {
    final jugadas = estadisticas.numPartidasJugadas;
    final ganadas = estadisticas.numPartidasGanadas;
    final winrate = jugadas == 0 ? 0.0 : (ganadas / jugadas) * 100;
    final regionFavorita = estadisticas.regionMasConquistada;

    return [
      PerfilEstadisticasItem(
        titulo: 'WINRATE',
        valor: '${winrate.toStringAsFixed(1)}%',
      ),
      const PerfilEstadisticasItem(
        titulo: 'RANKING MUNDIAL',
        valor: '0',
      ),
      PerfilEstadisticasItem(
        titulo: 'PARTIDAS JUGADAS',
        valor: '$jugadas',
      ),
      PerfilEstadisticasItem(
        titulo: 'VICTORIAS TOTALES',
        valor: '$ganadas',
      ),
      PerfilEstadisticasItem(
        titulo: 'BAJAS ENEMIGAS',
        valor: '${estadisticas.numSoldadosMatados}',
      ),
      PerfilEstadisticasItem(
        titulo: 'COMARCAS CONQUISTADAS',
        valor: '${estadisticas.numRegionesConquistadas}',
      ),
      PerfilEstadisticasItem(
        titulo: 'REGIONES CONQUISTADAS',
        valor: '${estadisticas.conquistasPorRegion.length}',
      ),
      PerfilEstadisticasItem(
        titulo: 'COMARCA FAVORITA',
        valor: (regionFavorita == null || regionFavorita.trim().isEmpty)
            ? 'Ninguna'
            : regionFavorita,
      ),
    ];
  }
}

class _PerfilInfoField extends StatelessWidget {
  const _PerfilInfoField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: AppTheme.bg.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.borderGold.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}



enum _ProfileActionButtonVariant {
  primary,
  danger,
}

class _ProfileActionButton extends StatefulWidget {
  const _ProfileActionButton({
    required this.text,
    required this.variant,
    required this.onPressed,
  });

  final String text;
  final _ProfileActionButtonVariant variant;
  final VoidCallback onPressed;

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  bool get _isPrimary => widget.variant == _ProfileActionButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isPrimary
        ? (_pressed ? AppTheme.borderGoldVivo : AppTheme.primary)
        : AppTheme.bg;

    final foregroundColor = _isPrimary ? AppTheme.bg : AppTheme.error;

    final borderColor = _isPrimary ? backgroundColor : AppTheme.error;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}



