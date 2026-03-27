import 'package:flutter/material.dart';

// CustomClipper para crear hexágonos alargados VERTICALMENTE con picos
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Pico arriba
    path.moveTo(width * 0.5, 0);
    // Lado derecho
    path.lineTo(width, height * 0.15);
    path.lineTo(width, height * 0.85);
    // Pico abajo
    path.lineTo(width * 0.5, height);
    // Lado izquierdo
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

  // Mapeo de fases a índices (0-4)
  static const Map<String, int> faseIndex = {
    'reclutamiento': 0,
    'ataque': 1,
    'retirada': 2,
    'fortificacion': 3,
    'reabastecimiento': 4,
  };

  static const List<String> faseDisplay = <String>[
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
  });

  String _normalizarFase(String fase) {
    return fase.trim().toLowerCase();
  }

  int _getFaseIndex() {
    return faseIndex[_normalizarFase(faseActual)] ?? 0;
  }

  String _getFaseDisplay(int index) {
    return faseDisplay[index];
  }

  bool _isUltimaFase(int index) {
    return index == faseDisplay.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = 130.0;
    final panelWidth = panelHeight * 2.1;
    final faseIndexActual = _getFaseIndex();
    final textoBoton = _isUltimaFase(faseIndexActual) ? 'FIN TURNO' : 'SIGUIENTE';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: panelWidth,
        height: panelHeight,
        margin: const EdgeInsets.only(bottom: 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. LA IMAGEN DE FONDO
            Image.asset(
              'assets/images/panel_mando.png',
              fit: BoxFit.contain,
            ),

            // 2. RETRATO DE PERFIL (Círculo izquierdo - CENTRADO VERTICALMENTE)
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

            // 3. TEXTO DE LA FASE (Centro arriba)
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

            // 4. RECTÁNGULOS ILUMINADOS (5 fases - CENTRO DEL PANEL)
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
                                color: const Color(0xFFFDD835)
                                    .withValues(alpha: 0.9),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFDD835)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipPath(
                            clipper: HexagonClipper(),
                            child: Container(
                              color: const Color(0xFFFDD835),
                            ),
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

            // 5. "SIGUIENTE" (Abajo DENTRO del panel)
            Positioned(
              bottom: panelHeight * 0.31,
              left: panelWidth * 0.265,
              right: panelWidth * 0.25,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onNextPhasePressed,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: panelHeight * 0.03,
                      vertical: panelHeight * 0.01,
                    ),
                    child: Text(
                      textoBoton,
                      style: TextStyle(
                        color: const Color(0xFFC6A664),
                        fontWeight: FontWeight.bold,
                        fontSize: panelHeight * 0.07,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 6. NÚMERO DE TROPAS (Círculo derecho - CENTRADO VERTICALMENTE, MÁS PEQUEÑO)
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
    );
  }
}