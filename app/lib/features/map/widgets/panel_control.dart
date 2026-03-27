import 'package:flutter/material.dart';

// CustomClipper para hexágonos verticales — sin tocar
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    path.moveTo(width * 0.5, 0);
    path.lineTo(width, height * 0.15);
    path.lineTo(width, height * 0.85);
    path.lineTo(width * 0.5, height);
    path.lineTo(0, height * 0.85);
    path.lineTo(0, height * 0.15);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(HexagonClipper oldClipper) => false;
}

class PanelControlGuerra extends StatelessWidget {
  final int tropas;
  final String faseActual;
  final VoidCallback onNextPhasePressed;

  // Nuevo: necesitamos saber quién juega para pintar el panel lateral
  final String turnoDe;
  final String usernamePropio;
  final Map<String, Color> coloresPorJugador; // username -> color

  static const Map<String, int> faseIndex = {
    'reclutamiento': 0,
    'ataque_convencional': 1,
    'retirada': 2,
    'fortificacion': 3,
    'reabastecimiento': 4,
  };

  static const List<String> faseDisplay = [
    'RECLUTAMIENTO',
    'ATAQUE',
    'RETIRADA',
    'FORTIFICACION',
    'REABASTECIMIENTO',
  ];

  const PanelControlGuerra({
    super.key,
    required this.tropas,
    required this.faseActual,
    required this.onNextPhasePressed,
    required this.turnoDe,
    required this.usernamePropio,
    required this.coloresPorJugador,
  });

  String _normalizarFase(String fase) => fase.trim().toLowerCase();

  int _getFaseIndex() => faseIndex[_normalizarFase(faseActual)] ?? 0;

  String _getFaseDisplay(int index) => faseDisplay[index];

  bool _isUltimaFase(int index) => index == faseDisplay.length - 1;

  @override
  Widget build(BuildContext context) {
    const panelHeight = 130.0;
    final panelWidth = panelHeight * 2.1;
    final faseIndexActual = _getFaseIndex();
    final textoBoton = _isUltimaFase(faseIndexActual) ? 'FIN TURNO' : 'SIGUIENTE';

    // Solo habilitamos el botón si es nuestro turno
    final esMiTurno = turnoDe == usernamePropio;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // --- PANEL LATERAL DE JUGADORES (a la izquierda del panel central) ---
        Positioned(
          bottom: 10,
          right: panelWidth / 2 + 10,
          child: _PanelJugadores(
            turnoDe: turnoDe,
            usernamePropio: usernamePropio,
            coloresPorJugador: coloresPorJugador,
          ),
        ),

        // --- EL PANEL CENTRAL (imagen + controles) ---
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: panelWidth,
            height: panelHeight,
            margin: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. IMAGEN DE FONDO
                Image.asset('assets/images/panel_mando.png', fit: BoxFit.contain),

                // 2. RETRATO DE PERFIL (círculo izquierdo)
                Positioned(
                  left: panelWidth * 0.0935,
                  top: panelHeight * 0.205,
                  child: Container(
                    width: panelHeight * 0.57,
                    height: panelHeight * 0.57,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white24,
                      size: panelHeight * 0.12,
                    ),
                  ),
                ),

                // 3. TEXTO DE FASE (centro arriba)
                Positioned(
                  top: panelHeight * 0.24,
                  left: panelWidth * 0.265,
                  right: panelWidth * 0.25,
                  child: Center(
                    child: Text(
                      _getFaseDisplay(faseIndexActual),
                      style: TextStyle(
                        color: const Color(0xFFC6A664),
                        fontWeight: FontWeight.bold,
                        fontSize: panelHeight * 0.07,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

                // 4. INDICADORES DE FASE (5 hexágonos)
                Positioned(
                  top: panelHeight * 0.297,
                  left: panelWidth * 0.2697,
                  right: panelWidth * 0.25,
                  child: Center(
                    child: SizedBox(
                      width: panelWidth * 0.246,
                      height: panelHeight * 0.26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final isActive = index == faseIndexActual;
                          final rectWidth = panelHeight * 0.075;
                          final rectHeight = panelHeight * 0.165;
                          if (isActive) {
                            return Container(
                              width: rectWidth,
                              height: rectHeight,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFDD835).withValues(alpha: 0.9),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFDD835).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipPath(
                                clipper: HexagonClipper(),
                                child: Container(color: const Color(0xFFFDD835)),
                              ),
                            );
                          } else {
                            return ClipPath(
                              clipper: HexagonClipper(),
                              child: Container(
                                width: rectWidth,
                                height: rectHeight,
                                color: Colors.transparent,
                              ),
                            );
                          }
                        }),
                      ),
                    ),
                  ),
                ),

                // 5. BOTÓN SIGUIENTE — deshabilitado visualmente si no es tu turno
                Positioned(
                  bottom: panelHeight * 0.31,
                  left: panelWidth * 0.265,
                  right: panelWidth * 0.25,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // null = no hace nada al tocar cuando no es tu turno
                      onTap: esMiTurno ? onNextPhasePressed : null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: panelHeight * 0.03,
                          vertical: panelHeight * 0.01,
                        ),
                        child: Text(
                          textoBoton,
                          style: TextStyle(
                            // Gris apagado si no es tu turno, dorado si sí
                            color: esMiTurno
                                ? const Color(0xFFC6A664)
                                : const Color(0xFF666666),
                            fontWeight: FontWeight.bold,
                            fontSize: panelHeight * 0.07,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. NÚMERO DE TROPAS (círculo derecho)
                Positioned(
                  right: panelWidth * 0.0905,
                  top: panelHeight * 0.24,
                  child: Container(
                    width: panelHeight * 0.5,
                    height: panelHeight * 0.5,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$tropas',
                        style: TextStyle(
                          color: const Color(0xFFC6A664),
                          fontSize: panelHeight * 0.25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Widget auxiliar privado: panel lateral con los jugadores ---
class _PanelJugadores extends StatelessWidget {
  final String turnoDe;
  final String usernamePropio;
  final Map<String, Color> coloresPorJugador;

  const _PanelJugadores({
    required this.turnoDe,
    required this.usernamePropio,
    required this.coloresPorJugador,
  });

  @override
  Widget build(BuildContext context) {
    if (coloresPorJugador.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC6A664).withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          const Text(
            'TURNO',
            style: TextStyle(
              color: Color(0xFFC6A664),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Una fila por jugador
          ...coloresPorJugador.entries.map((entry) {
            final username = entry.key;
            final color = entry.value;
            final esTurnoDeEste = username == turnoDe;
            final esTuyo = username == usernamePropio;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Punto de color del jugador
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: esTurnoDeEste ? 10 : 7,
                    height: esTurnoDeEste ? 10 : 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      // Brillo en el jugador activo
                      boxShadow: esTurnoDeEste
                          ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 1)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    // "(tú)" para que sepas quién eres sin leer el nombre entero
                    esTuyo ? '$username (tú)' : username,
                    style: TextStyle(
                      color: esTurnoDeEste ? Colors.white : Colors.white54,
                      fontSize: esTurnoDeEste ? 11 : 10,
                      fontWeight: esTurnoDeEste ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  // Flecha indicando turno activo
                  if (esTurnoDeEste) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.play_arrow, color: Color(0xFFC6A664), size: 12),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}