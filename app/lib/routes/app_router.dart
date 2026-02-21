import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/screens/splash_screen.dart';
import 'app_routes.dart';

import '../screens/home_screen.dart';
import '../screens/menu_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (BuildContext context, GoRouterState state) => SplashScreen(),
      //  return const HomeScreen(title: 'SOBERANÍA');
      //},
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(title: 'SOBERANÍA');
      },
    ),
    GoRoute(
      path: AppRoutes.menu,
      builder: (BuildContext context, GoRouterState state) {
        return const MenuScreen();
      },
    ),
  ],
);
