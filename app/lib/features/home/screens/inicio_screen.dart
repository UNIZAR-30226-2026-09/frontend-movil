import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../amigos/providers/global_websocket_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/auth_inicio_background.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(globalWebSocketProvider);

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: AuthInicioBackground(
        child: SizedBox.expand(
          child: Align(
            alignment: const Alignment(-0.05, 0.0),
            child: authState.status == AuthStatus.authenticated
                ? ElevatedButton(
                    onPressed: () {
                      context.go(AppRoutes.home);
                    },
                    child: Text(
                      'Entrar al campo',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                      ),  
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutes.login);
                        },
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                          ),  
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutes.registro);
                        },
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                          ),  
                        ),
                      ),
                    ],
                  ),
          ),
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