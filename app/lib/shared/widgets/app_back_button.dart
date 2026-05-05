import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppBackButton extends StatefulWidget {
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.size = 48,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _pressed ? AppTheme.borderGoldVivo : AppTheme.borderGold,
              width: _pressed ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.54),
                blurRadius: _pressed ? 9 : 12,
                offset: Offset(0, _pressed ? 3 : 4),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: _pressed ? AppTheme.borderGoldVivo : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}