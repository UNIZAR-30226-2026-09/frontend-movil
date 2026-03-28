import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../home/widgets/app_bottom_nav_bar.dart';
import '../../home/widgets/home_background.dart';
import '../../home/widgets/home_action_button.dart';
import '../widgets/partida_rapida_panel.dart';

class MenubatallasScreen extends StatefulWidget {
  const MenubatallasScreen({super.key});

  @override
  State<MenubatallasScreen> createState() => _MenubatallasScreenState();
}

class _MenubatallasScreenState extends State<MenubatallasScreen> {
  bool _showQuickMatch = false;
  bool _showQuickMatchOverlay = false;

  void _openQuickMatch() {
    setState(() {
      _showQuickMatchOverlay = true;
      _showQuickMatch = true;
    });
  }

  void _closeQuickMatch() {
    setState(() {
      _showQuickMatch = false;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _showQuickMatchOverlay = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Align(
                alignment: const Alignment(-0.07, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeActionButton(
                      text: 'Partida rápida',
                      onPressed: _openQuickMatch,
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
                        context.push(AppRoutes.lobbyPath(84));
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
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252530).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
              ),
            ),
            if (_showQuickMatchOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeQuickMatch,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showQuickMatch ? 1 : 0,
                    child: Container(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _showQuickMatch
                  ? PartidaRapidaPanel(
                      key: const ValueKey('quickMatchOpen'),
                      onClose: _closeQuickMatch,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('quickMatchClosed'),
                    ),
            ),
          ],
        ),
      ),
      //bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}