import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF1A1A24);
  static const surface = Color(0xFF252530);
  static const panelOverlay = Color.fromRGBO(26, 26, 36, 0.85);

  static const primary = Color(0xFFC5A059);
  static const borderGoldVivo = Color(0xFFFFD13B);
  static const secondary = Color(0xFF8C6D3F);

  static const text = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFFA0A0B0);
  static const success = Color(0xFF388E3C);
  static const error = Color(0xFFD32F2F);
  static const disabled = Color(0xFF616161);

  static const player1 = Color(0xFFE54545);
  static const player1Muted = Color(0xFFA34A4A);
  static const player2 = Color(0xFF33B1D4);
  static const player2Muted = Color(0xFF4A8594);
  static const player3 = Color(0xFF4CAE1E);
  static const player3Muted = Color(0xFF858A59);
  static const player4 = Color(0xFFF08A24);
  static const player4Muted = Color(0xFFC67C4E);

  static const mapLandNeutral = Color(0xFFD4C4A8);
  static const mapOcean = Color(0xFF111118);
  static const mapSelectOrigin = Color(0xFFE6B800);
  static const mapSelectTarget = Color(0xFFE63946);

  static const regionPirineosBase = Color(0xFF5A2E85);
  static const regionPirineosMedio = Color(0xFF7517C2);
  static const regionPirineosFuerte = Color(0xFF8F00FF);
  static const regionEstepasBase = Color(0xFF9E8D24);
  static const regionEstepasMedio = Color(0xFFCEB512);
  static const regionEstepasFuerte = Color(0xFFFFDD00);
  static const regionEbroBase = Color(0xFF2B738F);
  static const regionEbroMedio = Color(0xFF1698C6);
  static const regionEbroFuerte = Color(0xFF01BEFE);
  static const regionCamposBase = Color(0xFF9C5B21);
  static const regionCamposMedio = Color(0xFFCD6C10);
  static const regionCamposFuerte = Color(0xFFFF7D00);
  static const regionVallesBase = Color(0xFF68941B);
  static const regionVallesMedio = Color(0xFF8AC90E);
  static const regionVallesFuerte = Color(0xFFADFF02);
  static const regionSierrasBase = Color(0xFF8F1C4F);
  static const regionSierrasMedio = Color(0xFFC70E5E);
  static const regionSierrasFuerte = Color(0xFFFF006D);

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: bg,
      secondary: secondary,
      onSecondary: text,
      surface: surface,
      onSurface: text,
      error: error,
      onError: text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textSecondary),
      ),

      iconTheme: const IconThemeData(color: primary),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text, // título + iconos en neón
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.all(8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bg,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
      ),

      dividerColor: secondary,
    );
  }
}
