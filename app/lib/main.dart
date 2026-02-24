import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la orientación
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  // 1. Inicialización necesaria para servicios de plataforma
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Forzamos la orientación horizontal (lo que subió Alexis)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Soberania',
      routerConfig: appRouter,
      theme: AppTheme.neonDark(),
    );
  }
}