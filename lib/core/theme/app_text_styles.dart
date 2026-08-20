/// Estilos de texto compartilhados pelas telas do app.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'cyberpunk_theme.dart';

/// Reúne receitas de texto repetidas para manter a hierarquia visual
/// consistente entre resultado e histórico.
abstract final class AppTextStyles {
  /// Rótulo pequeno em caixa alta usado antes de cada valor.
  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    letterSpacing: 1,
  );

  /// Valor técnico monoespaçado, com tamanho ajustável para cada contexto.
  static TextStyle mono({double fontSize = 15}) {
    return TextStyle(
      color: AppColors.textPrimary,
      fontFamily: CyberpunkTheme.monoFontFamily,
      fontSize: fontSize,
    );
  }

  /// Legenda discreta usada em metadados do histórico.
  static const TextStyle mutedCaption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
  );

  /// Legenda centralizada da tela de histórico vazio.
  static const TextStyle emptyStateCaption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
  );

  /// Mensagem para quando um conteúdo estruturado não tem campos exibíveis.
  static const TextStyle secondaryMessage = TextStyle(
    color: AppColors.textSecondary,
  );
}
