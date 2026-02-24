import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class MenuAlianzasScreen extends StatefulWidget {
  const MenuAlianzasScreen({super.key, required this.title});

  final String title;

  @override
  State<MenuAlianzasScreen> createState() => _MenuAlianzasScreenState();
} 

class _MenuAlianzasScreenState extends State<MenuAlianzasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/Logo_Soberania.jpeg',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}