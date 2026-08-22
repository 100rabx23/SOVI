import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class SoviTypography {
  SoviTypography._();

  static TextStyle displayMetrics({Color color = SoviColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 48,
        height: 56 / 48,
        letterSpacing: -0.96, // -0.02em
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineLg({Color color = SoviColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.32,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle headlineMd({Color color = SoviColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        letterSpacing: -0.24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLg({Color color = SoviColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMd({Color color = SoviColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelSm({Color color = SoviColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelMono({Color color = SoviColors.onSurfaceVariant}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.7, // 0.05em
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelMonoSm({Color color = SoviColors.onSurfaceVariant}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
