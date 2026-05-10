import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../home/widgets/home_background.dart';
import '../widgets/amigos_panel.dart';
import '../../../shared/widgets/app_back_button.dart';

class SocialMenuScreen extends StatelessWidget {
  const SocialMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: HomeBackground(
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
                  child: AppBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}