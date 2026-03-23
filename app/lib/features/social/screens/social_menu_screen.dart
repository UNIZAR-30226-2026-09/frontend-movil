import 'package:flutter/material.dart';
import '../../home/widgets/app_bottom_nav_bar.dart';

class SocialMenuScreen extends StatefulWidget {
  const SocialMenuScreen({super.key});

  @override
  State<SocialMenuScreen> createState() => _SocialMenuScreenState();
}

class _SocialMenuScreenState extends State<SocialMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Pantalla Social'),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
    );
  }
}