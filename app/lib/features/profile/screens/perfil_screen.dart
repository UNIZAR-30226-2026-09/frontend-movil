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
                      SizedBox(
                        height: constraints.maxHeight,
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
                                      Expanded(
                                        child: Container(
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
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Estadísticas',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Expanded(
                                                child: estadisticasAsync.when(
                                                  data: _buildStatsGrid,
                                                  loading: _buildStatsLoading,
                                                  error: _buildStatsError,
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

  Widget _buildStatsGrid(EstadisticasModel estadisticas) {
    final jugadas = estadisticas.numPartidasJugadas;
    final ganadas = estadisticas.numPartidasGanadas;
    final winrate = jugadas == 0 ? 0.0 : (ganadas / jugadas) * 100;

    final cards = <_StatCardData>[
      _StatCardData(
        emoji: '⚔️',
        titulo: 'Partidas Jugadas',
        valor: '$jugadas',
      ),
      _StatCardData(
        emoji: '🏆',
        titulo: 'Tasa de Victorias',
        valor: '${winrate.toStringAsFixed(1)}%',
      ),
      _StatCardData(
        emoji: '💀',
        titulo: 'Soldados Aniquilados',
        valor: '${estadisticas.numSoldadosMatados}',
      ),
      _StatCardData(
        emoji: '🗺️',
        titulo: 'Regiones Conquistadas',
        valor: '${estadisticas.numRegionesConquistadas}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho > 700
            ? 4
            : ancho > 500
            ? 2
            : 1;

        return GridView.builder(
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columnas == 1 ? 4.0 : 2.2,
          ),
          itemBuilder: (_, index) {
            final card = cards[index];
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF211A12), Color(0xFF2B2218)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderGold, width: 1.1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(card.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            card.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.borderGoldVivo,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      card.valor,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCardData {
  final String emoji;
  final String titulo;
  final String valor;

  const _StatCardData({
    required this.emoji,
    required this.titulo,
    required this.valor,
  });
}