import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_avatar.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';

class HomeProfileCard extends StatelessWidget {
  const HomeProfileCard({super.key, required this.username, this.avatar});

  final String username;
  final String? avatar; 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardSize = screenWidth < 420 ? 135.0 : 160.0;
    final avatarRadius = screenWidth < 420 ? 44.0 : 54.0;
    final nameFontSize = screenWidth < 420 ? 13.0 : 15.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          context.push(AppRoutes.perfil);
        },
        child: Container(
          width: cardSize,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.borderGold, 
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.borderGold,
                    width: 1.2,
                  ),
                ),
                child: AppAvatar(
                  avatar: avatar, 
                  radius: avatarRadius
                ),
              ),
              const SizedBox(height: 9),
              Text(
                username.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
