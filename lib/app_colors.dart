import 'package:flutter/material.dart';

/// AppColors contains the color palette for Bank BRI branding.
class AppColors {
  // Primary BRI blue
  static const Color briBlue = Color(0xFF1A2A80);

  // Darker shade
  static const Color briDarkBlue = Color(0xFF3B38A0);

  // Lighter shade
  static const Color briLightBlue = Color(0xFF7A85C1);

  // Accent colors (from palette)
  static const Color briYellow = Color(0xFFB2B0E8);
  static const Color briLightGray = Color(0xFFF5F5F5);
  static const Color briDarkGray = Color(0xFF8A8A8A);

  // Generate a MaterialColor swatch for briBlue
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF0033A0,
    <int, Color>{
      50: Color(0xFFE6E8F6),
      100: Color(0xFFB3BDE6),
      200: Color(0xFF8093D6),
      300: Color(0xFF4D69C6),
      400: Color(0xFF2645BB),
      500: Color(0xFF1A2A80), // primary
      600: Color(0xFF002E94),
      700: Color(0xFF002683),
      800: Color(0xFF001E71),
      900: Color(0xFF001356),
    },
  );
}
