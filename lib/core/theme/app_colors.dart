import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF666666);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFCCCCCC);
  
  // Accent Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color blue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFFBBF24);
  
  // Gradient Colors (Light Mode)
  static const List<Color> lightGradient = [
    Color(0xFFE6F4FE),
    Color(0xFFF0F9FF),
    Color(0xFFFFFFFF),
  ];
  
  // Gradient Colors (Dark Mode)
  static const List<Color> darkGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
    Color(0xFF334155),
  ];
  
  // Glass Morphism
  static Color glassLight = Colors.white.withOpacity(0.18);
  static Color glassDark = Colors.white.withOpacity(0.10);
  static Color glassBorderLight = Colors.white.withOpacity(0.70);
  static Color glassBorderDark = Colors.white.withOpacity(0.15);
}
