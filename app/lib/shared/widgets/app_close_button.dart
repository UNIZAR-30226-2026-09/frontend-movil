import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppCloseButton extends StatefulWidget {
  const AppCloseButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.size = 42,
    this.icon = Icons.close_rounded,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final double size;
  final IconData icon;

  @override
  State<AppCloseButton> createState() => _AppCloseButtonState();
}

class _AppCloseButtonState extends State<AppCloseButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.borderGold.withValues(alpha: widget.enabled ? 1 : 0.45);

    final iconColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.primary.withValues(alpha: widget.enabled ? 1 : 0.45);

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _pressed ? 1.5 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: _pressed ? 8 : 10,
                offset: Offset(0, _pressed ? 3 : 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}