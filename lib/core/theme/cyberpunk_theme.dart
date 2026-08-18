/// Definição do [ThemeData] cyberpunk usado em todo o app.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Constrói o tema visual "cyberpunk" do aplicativo.
///
/// Mantido como uma função (em vez de um `ThemeData` const) porque
/// `ThemeData` não é constável quando combinamos vários sub-temas
/// (ex.: [ColorScheme], [AppBarTheme], etc.).
class CyberpunkTheme {
  const CyberpunkTheme._();

  /// Família de fonte usada nos textos "técnicos" (valores lidos, labels
  /// de código). Usamos uma fonte monoespaçada do próprio sistema, sem
  /// depender de baixar fontes externas, para o app funcionar 100% offline
  /// desde a primeira execução.
  static const String monoFontFamily = 'monospace';

  /// Tema escuro principal do aplicativo.
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: AppColors.neonCyan,
      onPrimary: AppColors.background,
      secondary: AppColors.neonMagenta,
      onSecondary: AppColors.background,
      tertiary: AppColors.neonPurple,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.neonRed,
      onError: AppColors.background,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,

      // Barra de app transparente, sem sombra: o "brilho" vem dos widgets
      // customizados (ver widgets/neon_container.dart), não do Material.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.neonCyan),
        titleTextStyle: TextStyle(
          color: AppColors.neonCyan,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
          fontFamily: monoFontFamily,
        ),
      ),

      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            titleLarge: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            bodyMedium: const TextStyle(color: AppColors.textPrimary),
            bodySmall: const TextStyle(color: AppColors.textSecondary),
          ),

      iconTheme: const IconThemeData(color: AppColors.neonCyan),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.neonCyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.neonCyan, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.neonPurple),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.neonCyan),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.neonCyan,
        textColor: AppColors.textPrimary,
      ),
    );
  }
}
