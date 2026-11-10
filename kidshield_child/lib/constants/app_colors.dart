import 'package:flutter/material.dart';

class AppColors {
  // Brand Wireframe Colors: Dark Navy, Royal Blue, Neon Cyan, Mint Green
  static const Color darkNavy = Color(0xFF060C1E);
  static const Color darkNavyCard = Color(0xFF0A1636);
  static const Color navyCardLight = Color(0xFF0F1E47);
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color mintGreen = Color(0xFF00E676);
  static const Color softGreen = Color(0xFF10B981);

  // Backgrounds & Surfaces
  static const Color backgroundDark = Color(0xFF050B1A);
  static const Color surfaceDark = Color(0xFF0A1636);
  static const Color cardDark = Color(0xFF0B1738);
  static const Color borderCyan = Color(0xFF00E5FF);
  static const Color borderDark = Color(0xFF1E3A8A);

  // Status & Safety
  static const Color sosRed = Color(0xFFEF4444);
  static const Color sosRedDark = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color amberAlert = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF00E5FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textCyan = Color(0xFF00E5FF);
  static const Color textDarkNavy = Color(0xFF050D24);

  // Compatibility aliases
  static const Color backgroundLight = Color(0xFF050B1A);
  static const Color surfaceLight = Color(0xFF0A1636);
  static const Color cardLight = Color(0xFF0B1738);
  static const Color borderLight = Color(0xFF1E3A8A);
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Wireframe Gradients
  static const LinearGradient navyBackgroundGradient = LinearGradient(
    colors: [Color(0xFF07112B), Color(0xFF040815)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanGlowButtonGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF0284C7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanGlowBorderGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient childGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
