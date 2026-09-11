import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// DEEPCHECK-CHAIN TASARIM SİSTEMİ
// Konsept: "Sıfır Güven Dünyasında, Gerçeğin Sarsılmaz Zinciri"
// ═══════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Arka plan katmanları ──
  static const Color background = Color(0xFF070B19);
  static const Color backgroundDeep = Color(0xFF0B132B);
  static const Color surface = Color(0xFF0F1A36);
  static const Color surfaceLight = Color(0xFF162040);
  static const Color cardBackground = Color(0xFF0A1628);

  // ── Vurgu renkleri – "Black & Gold" + Siberpunk ──
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8960C);
  static const Color goldLight = Color(0xFFFFF1B8);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonRed = Color(0xFFFF1744);
  static const Color neonPurple = Color(0xFFB388FF);

  // ── Durum renkleri ──
  static const Color successGlow = Color(0xFF00FF88);
  static const Color dangerGlow = Color(0xFFFF1744);

  // ── Metin renkleri ──
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8B9CB6);
  static const Color textMuted = Color(0xFF4A5568);

  // ── Glass efekti ──
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double full = 100.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontMono = 'monospace';

  static const TextStyle heading = TextStyle(
    fontFamily: fontMono,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontMono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.textMuted,
  );

  static const TextStyle hash = TextStyle(
    fontFamily: fontMono,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.gold,
  );
}