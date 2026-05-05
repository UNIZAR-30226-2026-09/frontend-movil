import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';

import '../../../app/router/app_routes.dart';
import '../widgets/home_action_button.dart';
import '../menu_background.dart';

import '../widgets/home_allies_panel.dart';
import '../widgets/home_center_block.dart';
import '../widgets/home_ranking_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? 'Jugador';
    final avatar = authState.user?.avatar;

    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;

              if (!isWide) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HomeCenterBlock(
                        username: username,
                        avatar: avatar,
                      ),
                      const SizedBox(height: 14),
                      HomeActionButton(
                        text: 'Aliados',
                        width: 300,
                        height: 72,
                        onPressed: () {
                          context.push(AppRoutes.social);
                        },
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: HomeRankingPanel(
                        currentUsername: username,
                      ),
                    ),
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(0, 55),
                      child: HomeCenterBlock(
                        username: username,
                        avatar: avatar,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: HomeAlliesPanel(
                        username: username,
                        avatar: avatar,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
