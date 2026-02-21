import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image(image:AssetImage('assets/images/Logo_Soberania.jpeg'),
          width: 250,
          fit: BoxFit.contain,
        ),
      )

    );
  }
}