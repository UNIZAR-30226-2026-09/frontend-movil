import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final username = authState.user?.username ?? 'Jugador';
    final email = authState.user?.email ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
          children: [
            SafeArea(
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                await ref.read(authProvider.notifier).logout();
                                                if (context.mounted) {
                                                  context.go('/inicio');
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1A1A24),
                                                foregroundColor: const Color(0xFFD32F2F),
                                                side: const BorderSide(
                                                  color: Color(0xFFD32F2F),
                                                  width: 1.2,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
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
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estadísticas',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Próximamente se mostrarán aquí las estadísticas del jugador.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFA0A0B0),
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
            if(_showEditProfileOverlay)
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
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
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
}