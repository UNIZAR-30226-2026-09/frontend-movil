import 'package:flutter/material.dart';

import '../utils/avatar_url_resolver.dart';

class AppAvatar extends StatelessWidget {
  final String? avatar;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final IconData fallbackIcon;

  const AppAvatar({
    super.key,
    required this.avatar,
    required this.radius,
    this.backgroundColor = const Color(0xFF1A1A24),
    this.iconColor = const Color(0xFFC5A059),
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveAvatarUrl(avatar);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? _AvatarFallback(icon: fallbackIcon, color: iconColor)
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _AvatarFallback(icon: fallbackIcon, color: iconColor);
              },
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _AvatarFallback({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: color));
  }
}
