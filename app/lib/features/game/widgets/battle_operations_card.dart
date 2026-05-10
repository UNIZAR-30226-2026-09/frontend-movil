import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class BattleOperationCard extends StatefulWidget {
  const BattleOperationCard({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  State<BattleOperationCard> createState() => _BattleOperationCardState();
}

class _BattleOperationCardState extends State<BattleOperationCard> {
  bool _buttonPressed = false;

  void _setButtonPressed(bool value) {
    if (_buttonPressed == value) return;

    setState(() {
      _buttonPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8C8AA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderBronze,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.bg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.borderBronze.withValues(alpha: 0.75),
                  AppTheme.borderBronze,
                  AppTheme.borderBronze.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
                stops: const [0, 0.18, 0.5, 0.82, 1],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: Text(
                widget.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.bg.withValues(alpha: 0.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTapDown: (_) => _setButtonPressed(true),
            onTapUp: (_) => _setButtonPressed(false),
            onTapCancel: () => _setButtonPressed(false),
            onTap: widget.onPressed,
            child: AnimatedScale(
              scale: _buttonPressed ? 0.96 : 1,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _buttonPressed
                        ? AppTheme.borderGoldVivo
                        : AppTheme.borderBronze,
                    width: _buttonPressed ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  '${widget.buttonText.toUpperCase()}  →',
                  style: TextStyle(
                    color: _buttonPressed
                        ? AppTheme.borderGoldVivo
                        : AppTheme.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    
    );
  }
}