import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import 'home_panel.dart';

class HomeAlliesPanel extends StatelessWidget {
  const HomeAlliesPanel({
    super.key,
    required this.username,
    this.avatar,
  });

  final String username;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      title: 'AMIGOS',
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: 1,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                return _OnlineFriendRow(
                  username: username,
                  avatar: avatar,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 160,
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.social);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.bg,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'VER ALIANZAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineFriendRow extends StatelessWidget {
  const _OnlineFriendRow({
    required this.username,
    this.avatar,
  });

  final String username;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppAvatar(
            avatar: avatar,
            radius: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Conectado',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}