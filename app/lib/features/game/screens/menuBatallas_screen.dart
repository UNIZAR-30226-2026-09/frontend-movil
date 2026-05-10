import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soberania/app/router/app_routes.dart';
import '../../home/widgets/home_background.dart';
import '../../home/widgets/home_action_button.dart';
import '../widgets/partida_rapida_panel.dart';
import '../widgets/crear_partida_panel.dart';
import '../widgets/unirse_partida_panel.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../widgets/battle_operations_panel.dart';

class MenubatallasScreen extends StatefulWidget {
  const MenubatallasScreen({super.key});

  @override
  State<MenubatallasScreen> createState() => _MenubatallasScreenState();
}

class _MenubatallasScreenState extends State<MenubatallasScreen> {
  bool _showQuickMatch = false;
  bool _showQuickMatchOverlay = false;
  bool _showCreateMatch = false;
  bool _showCreateMatchOverlay = false;
  bool _showUnirsePartida = false;
  bool _showUnirsePartidaOverlay = false;

  // ── Partida rápida ───────────────────────────────────────────────────────
  void _openQuickMatch() {
    setState(() {
      _showQuickMatchOverlay = true;
      _showQuickMatch = true;
    });
  }

  void _closeQuickMatch() {
    setState(() => _showQuickMatch = false);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _showQuickMatchOverlay = false);
    });
  }

  // ── Crear partida ────────────────────────────────────────────────────────
  void _openCreateMatch() {
    setState(() {
      _showCreateMatchOverlay = true;
      _showCreateMatch = true;
    });
  }

  void _closeCreateMatch() {
    setState(() => _showCreateMatch = false);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _showCreateMatchOverlay = false);
    });
  }

  // ── Unirse a partida ─────────────────────────────────────────────────────
  void _openUnirsePartida() {
    setState(() {
      _showUnirsePartidaOverlay = true;
      _showUnirsePartida = true;
    });
  }

  void _closeUnirsePartida() {
    setState(() => _showUnirsePartida = false);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _showUnirsePartidaOverlay = false);
    });
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: HomeBackground(
        child: Stack(
          children: [
            // ── Botones principales ────────────────────────────────────────
            SafeArea(
              child: BattleOperationsPanel(
                onQuickMatch: _openQuickMatch,
                onCreateMatch: _openCreateMatch,
                onJoinMatch: _openUnirsePartida,
              ),
            ),

            // ── Botón atrás ────────────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AppBackButton(
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ),
              ),
            ),

            // ── Overlay Partida rápida ─────────────────────────────────────
            if (_showQuickMatchOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeQuickMatch,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showQuickMatch ? 1 : 0,
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),

            // ── Overlay Crear partida ──────────────────────────────────────
            if (_showCreateMatchOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeCreateMatch,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showCreateMatch ? 1 : 0,
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),

            // ── Overlay Unirse a partida ───────────────────────────────────
            if (_showUnirsePartidaOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeUnirsePartida,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showUnirsePartida ? 1 : 0,
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),

            // ── Panel Partida rápida ───────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale:
                      Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _showQuickMatch
                  ? PartidaRapidaPanel(
                      key: const ValueKey('quickMatchOpen'),
                      onClose: _closeQuickMatch,
                    )
                  : const SizedBox.shrink(key: ValueKey('quickMatchClosed')),
            ),

            // ── Panel Crear partida ────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale:
                      Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _showCreateMatch
                  ? CrearPartidaPanel(
                      key: const ValueKey('createMatchOpen'),
                      onClose: _closeCreateMatch,
                    )
                  : const SizedBox.shrink(key: ValueKey('createMatchClosed')),
            ),

            // ── Panel Unirse a partida ─────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale:
                      Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _showUnirsePartida
                  ? UnirsePartidaPanel(
                      key: const ValueKey('unirsePartidaOpen'),
                      onClose: _closeUnirsePartida,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('unirsePartidaClosed')),
            ),
          ],
        ),
      ),
      //bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}