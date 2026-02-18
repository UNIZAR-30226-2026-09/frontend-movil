import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF050A1A);       // fondo muy oscuro azul
  static const surface = Color(0xFF0B1230);  // superficies (cards/appbar)
  static const neon = Color(0xFF4DD7FF);     // azul neón (acento)
  static const text = Color(0xFFEAF6FF);     // texto principal

  static ThemeData neonDark() {
    const scheme = ColorScheme.dark(
      primary: neon,
      onPrimary: Color(0xFF001018),
      secondary: Color(0xFF8AE9FF),
      onSecondary: Color(0xFF001018),
      surface: surface,
      onSurface: text,
      background: bg,
      onBackground: text,
      error: Color(0xFFFF4D6D),
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: text,
        displayColor: text,
      ),
      iconTheme: const IconThemeData(color: neon),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: neon, // título + iconos en neón
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(neon),
          foregroundColor: WidgetStatePropertyAll(Color(0xFF001018)),
        ),
      ),
    );
  }
}
