import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import 'home_action_button.dart';
import 'home_profile_card.dart';

class HomeCenterBlock extends StatelessWidget {
  const HomeCenterBlock({
    super.key,
    required this.username,
    this.avatar,
  });

  final String username;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeProfileCard(
          username: username,
          avatar: avatar,
        ),
        const SizedBox(height: 22),
        HomeActionButton(
          text: 'Jugar',
          subtitle: 'Accede al despliegue de operaciones',
          width: 300,
          height: 76,
          onPressed: () {
            context.push(AppRoutes.batallas);
          },
        ),
      ],
    );
  }
}