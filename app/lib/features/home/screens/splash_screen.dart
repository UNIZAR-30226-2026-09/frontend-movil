import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Cuando termina la comprobación inicial de sesión,
    // navegamos a la pantalla de inicio.
    if (authState.status == AuthStatus.authenticated ||
        authState.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.inicio);
      });
    }

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/Logo_Soberania.jpeg',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}