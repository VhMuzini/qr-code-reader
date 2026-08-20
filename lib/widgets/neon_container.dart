/// Cartão com borda e brilho neon, reutilizado em várias telas.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Um [Container] com borda colorida e um "glow" (brilho) ao redor,
/// simulando o visual de painéis holográficos comuns em interfaces
/// cyberpunk.
///
/// Encapsular esse efeito aqui evita repetir a mesma combinação de
/// [BoxDecoration] + [BoxShadow] em cada tela que precisa de um painel
/// neon (resultado, histórico, etc.).
class NeonContainer extends StatelessWidget {
  const NeonContainer({
    super.key,
    required this.child,
    this.color = AppColors.neonCyan,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.glowStrength = 0.35,
  });

  /// Conteúdo exibido dentro do painel.
  final Widget child;

  /// Cor da borda e do brilho.
  final Color color;

  /// Espaçamento interno do conteúdo.
  final EdgeInsetsGeometry padding;

  /// Raio das bordas arredondadas.
  final double borderRadius;

  /// Intensidade do brilho (0 a 1). Valores maiores deixam o glow mais
  /// visível, mas também mais "pesado" visualmente.
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowStrength),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }
}
