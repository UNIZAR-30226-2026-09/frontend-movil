import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../models/estadisticas_model.dart';
import '../providers/estadisticas_provider.dart';
import '../widgets/editar_perfil_panel.dart';
import '../../auth/providers/auth_provider.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.borderGoldVivo,
              onRefresh: () async {
                await ref.refresh(estadisticasProvider.future);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252530),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFC5A059),
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
                                constraints: const BoxConstraints(maxWidth: 750),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF252530),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFC5A059),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 180,
                                              child: Column(
                                                children: [
                                                  const CircleAvatar(
                                                    radius: 42,
                                                    backgroundColor: Color(0xFF1A1A24),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 42,
                                                      color: Color(0xFFC5A059),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Perfil de $username',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
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
                                                  Text(
                                                    'Usuario: $username',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'Correo: $email',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Color(0xFFA0A0B0),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    'Contraseña: ••••••••',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Color(0xFFA0A0B0),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  Row(
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: _openEditProfile,
                                                        child: const Text('Editar perfil'),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      OutlinedButton(
                                                        onPressed: () async {
                                                          await ref
                                                              .read(authProvider.notifier)
                                                              .logout();
                                                          if (context.mounted) {
                                                            context.go('/inicio');
                                                          }
                                                        },
                                                        style: OutlinedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(0xFF1A1A24),
                                                          foregroundColor:
                                                              const Color(0xFFD32F2F),
                                                          side: const BorderSide(
                                                            color: Color(0xFFD32F2F),
                                                            width: 1.2,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text('Cerrar sesión'),
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
                                          borderRadius: BorderRadius.circular(20),
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
                                        child: _buildStatsContainer(estadisticasAsync),
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
          ),
          if (_showEditProfileOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeEditProfile,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _showEditProfile ? 1 : 0,
                  child: Container(
                    color: Colors.black54,
                  ),
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
                  scale:
                      Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showEditProfile
                ? EditarPerfilPanel(
                    key: const ValueKey('editProfileOpen'),
                    onClose: _closeEditProfile,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('editProfileClosed'),
                  ),
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
          color: const Color(0xFF20171A),
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
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.borderGold, width: 1),
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
              estadisticasAsync.when(
                data: _buildStatsGrid,
                loading: _buildStatsLoading,
                error: _buildStatsError,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: _buildEsquinaOrnamental(top: true, left: true),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _buildEsquinaOrnamental(top: true, right: true),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildEsquinaOrnamental(bottom: true, left: true),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildEsquinaOrnamental(bottom: true, right: true),
        ),
      ],
    );
  }

  Widget _buildEsquinaOrnamental({
    bool top = false,
    bool right = false,
    bool bottom = false,
    bool left = false,
  }) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: top ? const BorderSide(color: AppTheme.borderGoldVivo, width: 3) : BorderSide.none,
          right: right ? const BorderSide(color: AppTheme.borderGoldVivo, width: 3) : BorderSide.none,
          bottom: bottom ? const BorderSide(color: AppTheme.borderGoldVivo, width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: AppTheme.borderGoldVivo, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(EstadisticasModel estadisticas) {
    final jugadas = estadisticas.numPartidasJugadas;
    final ganadas = estadisticas.numPartidasGanadas;
    final winrate = jugadas == 0 ? 0.0 : (ganadas / jugadas) * 100;
    final regionFavorita = estadisticas.regionMasConquistada;

    final stats = <Map<String, String>>[
      {'titulo': 'WINRATE', 'valor': '${winrate.toStringAsFixed(1)}%'},
      {'titulo': 'RANKING MUNDIAL', 'valor': '0'},
      {'titulo': 'PARTIDAS JUGADAS', 'valor': '$jugadas'},
      {'titulo': 'VICTORIAS TOTALES', 'valor': '$ganadas'},
      {
        'titulo': 'BAJAS ENEMIGAS',
        'valor': '${estadisticas.numSoldadosMatados}',
      },
      {
        'titulo': 'REGIONES CONQUISTADAS',
        'valor': '${estadisticas.numRegionesConquistadas}',
      },
      {
        'titulo': 'CONTINENTES CONQUISTADOS',
        'valor': '${estadisticas.conquistasPorRegion.length}',
      },
      {
        'titulo': 'REGION FAVORITA',
        'valor': (regionFavorita == null || regionFavorita.trim().isEmpty)
            ? 'Ninguna'
            : regionFavorita,
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
            (item) => _buildStatBox(
              titulo: item['titulo']!,
              valor: item['valor']!,
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatBox({
    required String titulo,
    required String valor,
  }) {
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