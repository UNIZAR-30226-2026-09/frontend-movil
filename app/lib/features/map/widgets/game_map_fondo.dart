import 'package:flutter/material.dart';

class GameMapBackground extends StatelessWidget {
  const GameMapBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: Transform.scale(
              scale: 1.10, // prueba entre 1.05 y 1.20
              child: Image.asset(
                'assets/images/fondo-mesa.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}