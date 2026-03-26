import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../home/widgets/app_bottom_nav_bar.dart';
import '../../home/widgets/home_background.dart';
import '../../home/widgets/home_action_button.dart';

class MenubatallasScreen extends StatelessWidget {
  const MenubatallasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBackground(
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(-0.05, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeActionButton(
                    text: 'Partida rápida',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 18),
                  HomeActionButton(
                    text: 'Crear partida',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 18),
                  HomeActionButton(
                    text: 'Introducir código',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: () {
                      context.push(AppRoutes.lobbyPath(1));
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF252530).withOpacity(0.92),
                      foregroundColor: const Color(0xFFC5A059),
                      side: const BorderSide(
                        color: Color(0xFFC5A059),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Entrar al lobby'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}