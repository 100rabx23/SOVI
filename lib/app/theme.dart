import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class SoviTheme {
  SoviTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: SoviColors.background,
      colorScheme: const ColorScheme.dark(
        surface: SoviColors.surface,
        onSurface: SoviColors.onSurface,
        primary: SoviColors.primary,
        onPrimary: SoviColors.onPrimary,
        secondary: SoviColors.secondary,
        onSecondary: SoviColors.onSecondary,
        error: SoviColors.error,
        onError: SoviColors.onError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
