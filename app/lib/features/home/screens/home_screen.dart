import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/home_background.dart';
import '../widgets/home_action_button.dart';
import '../widgets/home_profile_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? 'Jugador';
    return Scaffold(
      body: HomeBackground(
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(-0.14, 0),
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  HomeActionButton(
                    text: 'Entrar al lobby',
                    onPressed: () {
                      context.push(AppRoutes.lobbyPath(1));
                    },
                  ),
                  HomeActionButton(
                    text: 'Aliados',
                    onPressed: () {
                      context.push(AppRoutes.social);
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: HomeProfileCard(
                    username: username,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}