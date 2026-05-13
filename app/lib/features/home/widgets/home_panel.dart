import 'package:flutter/material.dart';
import 'dart:ui';


import '../../../app/theme/app_theme.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({
    super.key,
    required this.title,
    required this.child,
    this.height = 205,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3,
          sigmaY: 3,
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.borderGold,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Times New Roman',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: AppTheme.borderGold.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}