import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/perfil_publico_model.dart';
import '../providers/perfil_publico_provider.dart';
import '../widgets/perfil_estadisticas_panel.dart';
import '../../../shared/widgets/app_back_button.dart';

class PerfilPublicoScreen extends ConsumerWidget {
  const PerfilPublicoScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilPublicoProvider(username));

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
                              constraints: const BoxConstraints(maxWidth: 750),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  20,
                                ),
                                child: perfilAsync.when(
                                  loading: () => const _LoadingProfile(),
                                  error: (error, _) => _ProfileError(
                                    error: error,
                                    onRetry: () {
                                      ref.invalidate(
                                        perfilPublicoProvider(username),
                                      );
                                    },
                                  ),
                                  data: (perfil) {
                                    return Column(
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
                                                      avatar: perfil.avatar,
                                                      radius: 42,
                                                      fallbackIcon:
                                                          Icons.person,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Perfil de ${perfil.nombreUser}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color:
                                                            AppTheme.borderGold,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Times New Roman',
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
                                                      label:
                                                          'Nombre de usuario',
                                                      value: perfil.nombreUser,
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
                                          child: PerfilEstadisticasPanel(
                                            stats: _buildStats(perfil),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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
        ],
      ),
    );
  }

  List<PerfilEstadisticasItem> _buildStats(PerfilPublicoModel perfil) {
    return [
      PerfilEstadisticasItem(
        titulo: 'WINRATE',
        valor: '${perfil.winrate.toStringAsFixed(1)}%',
      ),
      PerfilEstadisticasItem(
        titulo: 'RANKING MUNDIAL',
        valor: perfil.posicionRanking?.toString() ?? '0',
      ),
      PerfilEstadisticasItem(
        titulo: 'PARTIDAS JUGADAS',
        valor: '${perfil.numPartidasJugadas}',
      ),
      PerfilEstadisticasItem(
        titulo: 'VICTORIAS TOTALES',
        valor: '${perfil.numPartidasGanadas}',
      ),
      PerfilEstadisticasItem(
        titulo: 'BAJAS ENEMIGAS',
        valor: '${perfil.numSoldadosMatados}',
      ),
      PerfilEstadisticasItem(
        titulo: 'COMARCAS CONQUISTADAS',
        valor: '${perfil.numComarcasConquistadas}',
      ),
      PerfilEstadisticasItem(
        titulo: 'REGIONES CONQUISTADAS',
        valor: '${perfil.numRegionesConquistadas}',
      ),
      PerfilEstadisticasItem(
        titulo: 'COMARCA FAVORITA',
        valor: perfil.comarcaMasConquistada ?? 'Ninguna',
      ),
    ];
  }
}

class _LoadingProfile extends StatelessWidget {
  const _LoadingProfile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppTheme.borderGoldVivo,
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              'No pudimos cargar el perfil.',
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
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _PerfilInfoField extends StatelessWidget {
  const _PerfilInfoField({required this.label, required this.value});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
