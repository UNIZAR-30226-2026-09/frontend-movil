import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la orientación
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // 1. Inicialización necesaria para servicios de plataforma
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 2. Forzamos la orientación horizontal (lo que subió Alexis)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState(){
    super.initState();
    // Al arrancar la app, comprobamos si hay una sesión guardada.
    Future.microtask(() {
      ref.read(authProvider.notifier).checkSession();
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Soberania',
      routerConfig: appRouter,
      theme: AppTheme.neonDark(),
    );
  }
}