import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF1A1A24);       // fondo muy oscuro azul
  static const surface = Color(0xFF252530);  // superficies (cards/appbar)
  static const primary = Color(0xFFC5A059);     // azul neón (acento)
  static const secondary = Color(0xFF8C6D3F);   // Bronce
  static const text = Color(0xFFF0F0F5);     // texto principal
  static const textSecondary = Color(0xFFA0A0B0);
  static const error = Color(0xFFD32F2F);

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: bg,
      secondary: secondary,
      onSecondary: text,
      surface: surface,
      onSurface: text,
      error: error,
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: textSecondary,
        ),
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
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
          )
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
