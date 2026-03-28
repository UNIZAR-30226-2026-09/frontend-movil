import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({
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
            'assets/images/mesa-mando.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}