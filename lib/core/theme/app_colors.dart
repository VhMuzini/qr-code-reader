/// Paleta de cores do app.
///
/// Centralizar as cores aqui evita "cores mágicas" espalhadas pelas telas
/// e garante que o visual cyberpunk (fundo escuro + neon) fique consistente
/// em todos os widgets.
library;

import 'package:flutter/material.dart';

/// Cores usadas para montar o tema cyberpunk do app.
///
/// A ideia visual é a de uma interface "hacker/terminal futurista":
/// fundo quase preto, detalhes em ciano e magenta neon, e um roxo
/// elétrico como cor de apoio.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Fundo
  // ---------------------------------------------------------------------

  /// Preto azulado profundo, usado como fundo principal das telas.
  static const Color background = Color(0xFF06060B);

  /// Um pouco mais claro que [background]; usado em cartões e superfícies
  /// elevadas (ex.: itens de lista, painéis).
  static const Color surface = Color(0xFF10101B);

  /// [surface] com 80% de opacidade, usado sobre a prévia da câmera.
  ///
  /// O valor hexadecimal mantém a mesma cor resultante de
  /// `surface.withValues(alpha: 0.8)` e continua compatível com parâmetros
  /// `const` de widgets.
  static const Color surfaceOverlay = Color(0xCC10101B);

  /// [background] com 80% de opacidade, usado para escurecer a câmera.
  ///
  /// O valor hexadecimal mantém a mesma cor resultante de
  /// `background.withValues(alpha: 0.8)` e continua compatível com
  /// parâmetros `const` de widgets.
  static const Color backgroundOverlay = Color(0xCC06060B);

  /// Superfície ainda mais clara, para elementos "dentro" de um cartão.
  static const Color surfaceHigh = Color(0xFF1A1A2E);

  // ---------------------------------------------------------------------
  // Cores neon (acento)
  // ---------------------------------------------------------------------

  /// Ciano neon: cor primária do app (bordas, textos de destaque, brilho).
  static const Color neonCyan = Color(0xFF00F0FF);

  /// Magenta neon: cor secundária, usada em ações e destaques alternativos.
  static const Color neonMagenta = Color(0xFFFF2BD1);

  /// Roxo elétrico: cor de apoio para gradientes e sombras.
  static const Color neonPurple = Color(0xFF8A2BFF);

  /// Verde neon: reservado para estados de sucesso (ex.: leitura concluída).
  static const Color neonGreen = Color(0xFF39FF88);

  /// Vermelho/rosa de alerta, para erros ou ações destrutivas.
  static const Color neonRed = Color(0xFFFF3860);

  // ---------------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------------

  /// Texto principal (quase branco, levemente azulado).
  static const Color textPrimary = Color(0xFFE6F9FF);

  /// Texto secundário, para legendas e metadados.
  static const Color textSecondary = Color(0xFF8FA3B8);

  /// Texto ainda mais discreto, para placeholders e dicas.
  static const Color textMuted = Color(0xFF5C6B7A);

  /// Linhas de divisão sutis sobre o fundo escuro.
  static const Color divider = Color(0xFF232338);
}
