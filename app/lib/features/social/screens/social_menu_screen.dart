import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../home/widgets/home_background.dart';
import '../widgets/amigos_panel.dart';

class SocialMenuScreen extends StatelessWidget {
  const SocialMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: HomeBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 72, 16, 24),
                    child: AmigosPanel(),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                left: 16,
                child: _BackButtonBox(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButtonBox extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonBox({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panelOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppTheme.borderGold,
          width: 1.4,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}