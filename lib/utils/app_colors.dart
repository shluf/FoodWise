import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF3AA856);
  static const Color secondaryColor = Color(0xFF76C893);
  static const Color accentColor = Color(0xFFB7E4C7);
  
  static const Color backgroundColor = Color(0xFFF5F7F9);
  static const Color surfaceColor = Colors.white;
  
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Colors.white;
  
  static const Color successColor = Color(0xFF2ECC71);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color warningColor = Color(0xFFFFBB12);
  static const Color infoColor = Color(0xFF3498DB);
  
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient cardGradient = const LinearGradient(
    colors: [surfaceColor, Color(0xFFF7FCFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} 