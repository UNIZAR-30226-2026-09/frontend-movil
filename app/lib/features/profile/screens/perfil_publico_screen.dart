import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/perfil_publico_model.dart';
import '../providers/perfil_publico_provider.dart';

class PerfilPublicoScreen extends ConsumerWidget {
  const PerfilPublicoScreen({
    super.key,
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilPublicoProvider(username));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.borderGoldVivo,
              onRefresh: () async {
                ref.invalidate(perfilPublicoProvider(username));
                await ref.read(perfilPublicoProvider(username).future);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.borderGold,
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () => context.pop(),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                                  CrossAxisAlignment.start,
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
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'Perfil de ${perfil.nombreUser}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            const TextStyle(
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Usuario: ${perfil.nombreUser}',
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 18,
                                                        ),
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                            child: _StatsContainer(
                                              perfil: perfil,
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
          ),
        ],
      ),
    );
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
  const _ProfileError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mensaje = error.toString().replaceFirst('Exception: ', '');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF20171A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.7),
          ),
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
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsContainer extends StatelessWidget {
  const _StatsContainer({
    required this.perfil,
  });

  final PerfilPublicoModel perfil;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: AppTheme.borderGold,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'ESTADÍSTICAS GLOBALES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.borderGoldVivo,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Times New Roman',
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              _StatsGrid(perfil: perfil),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          child: _OrnamentalCorner(top: true, left: true),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: _OrnamentalCorner(top: true, right: true),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          child: _OrnamentalCorner(bottom: true, left: true),
        ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: _OrnamentalCorner(bottom: true, right: true),
        ),
      ],
    );
  }
}

class _OrnamentalCorner extends StatelessWidget {
  const _OrnamentalCorner({
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.left = false,
  });

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: top
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          right: right
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          bottom: bottom
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          left: left
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.perfil,
  });

  final PerfilPublicoModel perfil;

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, String>>[
      {
        'titulo': 'WINRATE',
        'valor': '${perfil.winrate.toStringAsFixed(1)}%',
      },
      {
        'titulo': 'RANKING MUNDIAL',
        'valor': perfil.posicionRanking?.toString() ?? '0',
      },
      {
        'titulo': 'PARTIDAS JUGADAS',
        'valor': '${perfil.numPartidasJugadas}',
      },
      {
        'titulo': 'VICTORIAS TOTALES',
        'valor': '${perfil.numPartidasGanadas}',
      },
      {
        'titulo': 'BAJAS ENEMIGAS',
        'valor': '${perfil.numSoldadosMatados}',
      },
      {
        'titulo': 'REGIONES CONQUISTADAS',
        'valor': '${perfil.numRegionesConquistadas}',
      },
      {
        'titulo': 'COMARCAS CONQUISTADAS',
        'valor': '${perfil.numComarcasConquistadas}',
      },
      {
        'titulo': 'COMARCA FAVORITA',
        'valor': perfil.comarcaMasConquistada ?? 'Ninguna',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: stats
          .map(
            (item) => _StatBox(
              titulo: item['titulo']!,
              valor: item['valor']!,
            ),
          )
          .toList(),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080808),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}