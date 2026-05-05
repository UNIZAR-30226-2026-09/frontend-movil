import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_avatar.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';

class HomeProfileCard extends StatefulWidget {
  const HomeProfileCard({super.key, required this.username, this.avatar});

  final String username;
  final String? avatar; 

  @override
  State<HomeProfileCard> createState() => _HomeProfileCardState();
}

class _HomeProfileCardState extends State<HomeProfileCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardSize = screenWidth < 420 ? 135.0 : 160.0;
    final avatarRadius = screenWidth < 420 ? 44.0 : 54.0;
    final nameFontSize = screenWidth < 420 ? 13.0 : 15.0;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: AppTheme.primary.withValues(alpha: 0.14),
          highlightColor: AppTheme.primary.withValues(alpha: 0.08),
          onHighlightChanged: _setPressed,
          onTap: () {
            context.push(AppRoutes.perfil);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 3,
                sigmaY: 3,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                width: cardSize,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: _pressed
                      ? AppTheme.surface.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _pressed ? AppTheme.borderGold : AppTheme.primary,
                    width: _pressed ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _pressed ? 0.38 : 0.3),
                      blurRadius: _pressed ? 14 : 18,
                      offset: Offset(0, _pressed ? 5 : 8),
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
                        avatar: widget.avatar,
                        radius: avatarRadius,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _pressed ? AppTheme.text : AppTheme.bg,
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
          ),
        ),
      ),
    );
  }
}
