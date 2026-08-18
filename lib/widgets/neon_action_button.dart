/// Botão de ação estilizado, usado na tela de resultado (Abrir, Copiar,
/// Compartilhar, etc.).
library;

import 'package:flutter/material.dart';

/// Botão retangular com ícone + rótulo e contorno neon.
///
/// Diferente de um [ElevatedButton] comum, ele é pensado para caber em
/// uma grade/linha de ações (ícone acima, texto abaixo) — o formato usado
/// nas ações contextuais da tela de resultado (ex.: "Abrir", "Copiar").
class NeonActionButton extends StatelessWidget {
  const NeonActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF00F0FF),
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10101B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
