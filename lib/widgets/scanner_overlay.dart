/// Moldura de mira estilo cyberpunk desenhada sobre a prévia da câmera.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Desenha a "janela de escaneamento": um recorte quadrado com cantos em
/// destaque (estilo mira/HUD) e uma linha de laser animada que sobe e
/// desce dentro da área, reforçando a sensação de leitura ativa.
///
/// É um [StatefulWidget] porque controla sua própria animação da linha de
/// laser; assim as telas que o usam não precisam gerenciar um
/// [AnimationController] à parte.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    this.color = AppColors.neonCyan,
    this.cutOutSize = 260,
    this.borderRadius = 24,
  });

  /// Cor da moldura e do laser.
  final Color color;

  /// Tamanho (lado) da área quadrada de escaneamento.
  final double cutOutSize;

  /// Raio de arredondamento do recorte central.
  final double borderRadius;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // A moldura é puramente decorativa: toques devem passar direto
      // para a prévia da câmera / botões por trás dela.
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(
              color: widget.color,
              cutOutSize: widget.cutOutSize,
              borderRadius: widget.borderRadius,
              laserPosition: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.color,
    required this.cutOutSize,
    required this.borderRadius,
    required this.laserPosition,
  });

  final Color color;
  final double cutOutSize;
  final double borderRadius;

  /// Posição vertical do laser dentro da área de corte, de 0.0 a 1.0.
  final double laserPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );
    final cutOutRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );

    _paintDimmedBackground(canvas, size, cutOutRRect);
    _paintCornerBrackets(canvas, cutOutRect);
    _paintLaserLine(canvas, cutOutRect);
  }

  /// Escurece toda a tela, exceto a área quadrada de escaneamento, para
  /// guiar o olhar do usuário para onde o QR Code deve ser posicionado.
  void _paintDimmedBackground(Canvas canvas, Size size, RRect cutOut) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutOutPath = Path()..addRRect(cutOut);

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutOutPath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = AppColors.backgroundOverlay,
    );
  }

  /// Desenha os quatro cantos em destaque ao redor do recorte, no estilo
  /// de mira/HUD (em vez de uma borda completa e "quadrada" demais).
  void _paintCornerBrackets(Canvas canvas, Rect rect) {
    const bracketLength = 28.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset corner, Offset horizontal, Offset vertical) {
      canvas.drawLine(corner, corner + horizontal, paint);
      canvas.drawLine(corner, corner + vertical, paint);
    }

    drawCorner(
      rect.topLeft,
      Offset(bracketLength, 0),
      Offset(0, bracketLength),
    );
    drawCorner(
      rect.topRight,
      Offset(-bracketLength, 0),
      Offset(0, bracketLength),
    );
    drawCorner(
      rect.bottomLeft,
      Offset(bracketLength, 0),
      Offset(0, -bracketLength),
    );
    drawCorner(
      rect.bottomRight,
      Offset(-bracketLength, 0),
      Offset(0, -bracketLength),
    );
  }

  /// Desenha a linha de laser horizontal que varre a área de escaneamento
  /// de cima para baixo (e volta), com um leve gradiente de brilho.
  void _paintLaserLine(Canvas canvas, Rect rect) {
    final y = rect.top + rect.height * laserPosition;

    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.9),
        color.withValues(alpha: 0),
      ],
    );

    final laserRect = Rect.fromLTWH(rect.left, y - 1.5, rect.width, 3);
    final paint = Paint()..shader = gradient.createShader(laserRect);

    canvas.drawRect(laserRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserPosition != laserPosition ||
        oldDelegate.color != color ||
        oldDelegate.cutOutSize != cutOutSize;
  }
}
