import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class HomeActionButton extends StatefulWidget {
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
  State<HomeActionButton> createState() => _HomeActionButtonState();
}

class _HomeActionButtonState extends State<HomeActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
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
          width: widget.width,
          height: widget.height,
          // En compacto recorto padding vertical para que el contenido no se coma la altura.
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 14 : 18,
            vertical: widget.compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _pressed ? AppTheme.borderGoldVivo : AppTheme.borderGold,
              width: _pressed ? 1.7 : 1.35,
            ),
          ),
          child: Column(
            // Esto deja que la columna mida solo lo justo y evita overflow en alturas ajustadas.
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: widget.compact ? 15 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: widget.compact ? 2.2 : 4,
                  ),
                ),
              ),
              if (hasSubtitle) ...[
                SizedBox(height: widget.compact ? 2 : 4),
                Flexible(
                  child: Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.62),
                      fontSize: widget.compact ? 10 : 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}