import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? 'Jugador';

    return Scaffold(
      body: SafeArea(
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
                                  const Text(
                                    'Contraseña: ••••••••',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFFA0A0B0),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Cambiar contraseña'),
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
    );
  }
}