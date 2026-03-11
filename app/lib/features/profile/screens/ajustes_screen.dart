import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';

/// Pantalla de ajustes de la aplicación.
/// Desde aquí el usuario puede cerrar su sesión.
class AjustesScreen extends ConsumerStatefulWidget {
  const AjustesScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends ConsumerState<AjustesScreen> {
  /// Cierra la sesión del usuario eliminando el token guardado
  /// y redirige a la pantalla de inicio.
  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleLogout,
          child: const Text('Cerrar sesión'),
        ),
      ),
    );
  }
}