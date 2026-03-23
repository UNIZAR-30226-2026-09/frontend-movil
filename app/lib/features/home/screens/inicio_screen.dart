import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SOBERANÍA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            authState.status == AuthStatus.authenticated
                ? ElevatedButton(
                    onPressed: () {
                      context.go(AppRoutes.home);
                    },
                    child: const Text('Iniciar'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutes.login);
                        },
                        child: const Text('Iniciar sesión'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutes.registro);
                        },
                        child: const Text('Registrarse'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Acceso temporal',
        onPressed: () {
          context.go(AppRoutes.home);
        },
        child: const Icon(Icons.login),
      ),
    );  
  }
}