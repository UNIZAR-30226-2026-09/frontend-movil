import 'package:flutter/material.dart';

class AuthInicioBackground extends StatelessWidget {
  const AuthInicioBackground({
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
            'assets/images/fondo-login.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        SafeArea(
          child: child,
        ),
      ],
    );
  }
}