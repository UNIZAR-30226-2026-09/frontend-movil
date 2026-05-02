import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class InfoPartidaPanel extends StatelessWidget {
  final String faseActual;
  final String turnoDe;
  final Color colorTurno;

  const InfoPartidaPanel({
    super.key,
    required this.faseActual,
    required this.turnoDe,
    required this.colorTurno,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D22).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderGold.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: 0.7853981634,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorTurno,
                  border: Border.all(
                    color: AppTheme.borderGold.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
