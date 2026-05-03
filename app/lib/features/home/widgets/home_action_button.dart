import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.subtitle,
    this.width = 260,
    this.height = 64,
    this.compact = false,
  });

  final String text;
  final String? subtitle;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surface.withValues(alpha: 0.96),
          side: const BorderSide(
            color: AppTheme.borderGold,
            width: 1.35,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 2.4 : 4,
              ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.62),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}