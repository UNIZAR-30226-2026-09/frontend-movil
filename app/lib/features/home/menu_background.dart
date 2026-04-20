import 'package:flutter/material.dart';

class MenuBackground extends StatelessWidget {
  const MenuBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/fondoLobby.png',
            fit: BoxFit.fitWidth,
            alignment: const Alignment(0, -1),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}