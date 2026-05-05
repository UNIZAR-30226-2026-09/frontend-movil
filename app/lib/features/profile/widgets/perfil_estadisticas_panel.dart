import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class PerfilEstadisticasItem {
  const PerfilEstadisticasItem({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;
}

class PerfilEstadisticasPanel extends StatelessWidget {
  const PerfilEstadisticasPanel({
    super.key,
    required this.stats,
  });

  final List<PerfilEstadisticasItem> stats;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(
            color: AppTheme.borderGold,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'ESTADÍSTICAS GLOBALES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.borderGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Times New Roman',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.borderBronze.withValues(alpha: 0.45),
                      AppTheme.borderGoldVivo.withValues(alpha: 0.65),
                      AppTheme.borderGoldVivo.withValues(alpha: 0.65),
                      AppTheme.borderBronze.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.10, 0.34, 0.66, 0.90, 1],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 16,
                childAspectRatio: 2.55,
                children: stats
                    .map(
                      (item) => _PerfilStatBox(
                        titulo: item.titulo,
                        valor: item.valor,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: _InnerPanelShadow(),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          child: _OrnamentalCorner(top: true, left: true),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: _OrnamentalCorner(top: true, right: true),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          child: _OrnamentalCorner(bottom: true, left: true),
        ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: _OrnamentalCorner(bottom: true, right: true),
        ),
      ],
    );
  }
}

class _OrnamentalCorner extends StatelessWidget {
  const _OrnamentalCorner({
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.left = false,
  });

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: top
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          right: right
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          bottom: bottom
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
          left: left
              ? const BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 3,
                )
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _InnerPanelShadow extends StatelessWidget {
  const _InnerPanelShadow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 1,
          left: 1,
          right: 1,
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 1,
          left: 1,
          right: 1,
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 1,
          bottom: 1,
          left: 1,
          width: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 1,
          bottom: 1,
          right: 1,
          width: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfilStatBox extends StatelessWidget {
  const _PerfilStatBox({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.92),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.65),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Times New Roman',
              letterSpacing: 1.4,
              height: 1.05,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 25),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(
                    color: AppTheme.primary.withValues(alpha: 0.22),
                    offset: const Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}