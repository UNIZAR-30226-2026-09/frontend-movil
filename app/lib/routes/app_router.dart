import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../screens/screens.dart';

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
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(title: 'SOBERANÍA'),
    ),
    GoRoute(
      path: AppRoutes.menu,
      builder: (BuildContext context, GoRouterState state) => const MenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.ajustes,
      builder: (BuildContext context, GoRouterState state) => const AjustesScreen(title: 'Ajustes'),
    ),
    GoRoute(
      path: AppRoutes.perfil,
      builder: (BuildContext context, GoRouterState state) => const PerfilScreen(title: 'Perfil'),
    ),
    GoRoute(
      path: AppRoutes.alianzas,
      builder: (BuildContext context, GoRouterState state) => const MenuAlianzasScreen(title: 'Alianzas'),
    ),
    GoRoute(
      path: AppRoutes.batallas,
      builder: (BuildContext context, GoRouterState state) => const MenubatallasScreen(title: 'Batallas'),
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
  ],
);
