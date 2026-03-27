import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/game/screens/lobby_screen.dart';
import 'package:soberania/features/home/screens/inicio_screen.dart';
import 'package:soberania/features/auth/screens/login_screen.dart';
import 'package:soberania/features/auth/screens/registrar_screen.dart';
import 'package:soberania/features/social/screens/social_menu_screen.dart';
import 'app_routes.dart';
import '../../shared/screens/screens.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      //  return const HomeScreen(title: 'SOBERANÍA');
      //},
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.inicio,
      builder: (BuildContext context, GoRouterState state) => const InicioScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder:(BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.registro,
      builder:(BuildContext context, GoRouterState state) => const RegistrarScreen(),
    ),
    GoRoute(
      path: AppRoutes.ajustes,
      builder: (BuildContext context, GoRouterState state) => const AjustesScreen(title: 'Ajustes'),
    ),
    GoRoute(
      path: AppRoutes.perfil,
      builder: (BuildContext context, GoRouterState state) => const PerfilScreen(),
    ),
    GoRoute(
      path: AppRoutes.alianzas,
      builder: (BuildContext context, GoRouterState state) => const MenuAlianzasScreen(title: 'Alianzas'),
    ),
    GoRoute(
      path: AppRoutes.batallas,
      builder: (BuildContext context, GoRouterState state) => const MenubatallasScreen(),
    ),   
    GoRoute(
      path: AppRoutes.batalla,
      builder: (BuildContext context, GoRouterState state) => const BatallaScreen(title: 'Batalla'),
    ),
    GoRoute(
      path: AppRoutes.arbol,
      builder: (BuildContext context, GoRouterState state) => const ArbolScreen(title: 'Árbol tecnológico'),
    ),
    GoRoute(
      path: AppRoutes.carga,
      builder: (BuildContext context, GoRouterState state) => const CargaScreen(),
    ),
    GoRoute(
      path: AppRoutes.social,
      builder: (BuildContext context, GoRouterState state) => const SocialMenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.lobby,
      builder: (BuildContext context, GoRouterState state) {
          final partidaId = int.parse(state.pathParameters['partidaId']!);
          return LobbyScreen(partidaId: partidaId);
      },
    ),
  ],
);
