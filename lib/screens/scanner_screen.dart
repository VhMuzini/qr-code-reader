/// Tela principal do app: câmera ao vivo procurando por um QR Code.
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_colors.dart';
import '../models/scan_history_entry.dart';
import '../services/qr_content_parser.dart';
import '../services/scan_history_service.dart';
import '../widgets/scanner_overlay.dart';
import 'history_screen.dart';
import 'result_screen.dart';

/// Tela inicial do app.
///
/// Mostra a prévia da câmera com uma mira animada por cima e, assim que
/// um QR Code é detectado, navega para [ResultScreen] com o conteúdo já
/// interpretado. Também é responsável por salvar cada leitura no
/// histórico local.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  /// Controlador da câmera/scanner. Restrito a QR Code (não outros
  /// formatos de código de barras) porque é isso que o app se propõe a
  /// ler.
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final ScanHistoryService _historyService = ScanHistoryService();

  /// Evita processar múltiplas detecções enquanto já estamos navegando
  /// para a tela de resultado (a câmera pode emitir vários frames com o
  /// mesmo código antes de conseguirmos pausá-la).
  bool _isNavigatingToResult = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isNavigatingToResult) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isNavigatingToResult = true;
    await _controller.stop();

    final parsed = QrContentParser.parse(rawValue);

    await _historyService.addEntry(
      ScanHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        rawValue: parsed.rawValue,
        type: parsed.type,
        scannedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(content: parsed)),
    );

    // Ao voltar da tela de resultado, retomamos a leitura.
    _isNavigatingToResult = false;
    if (mounted) {
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('QR SCAN'),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const ScannerOverlay(),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Aponte a câmera para um QR Code',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScannerControlButton(
                      icon: Icons.cameraswitch_rounded,
                      onPressed: () => _controller.switchCamera(),
                    ),
                    const SizedBox(width: 24),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _ScannerControlButton(
                          icon: isTorchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          isActive: isTorchOn,
                          onPressed: () => _controller.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão circular flutuante usado nos controles inferiores da câmera
/// (trocar câmera / lanterna).
class _ScannerControlButton extends StatelessWidget {
  const _ScannerControlButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.neonGreen : AppColors.neonCyan;
    return Material(
      color: const Color(0xCC10101B),
      shape: CircleBorder(side: BorderSide(color: color)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
