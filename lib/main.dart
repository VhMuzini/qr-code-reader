/// Ponto de entrada do app.
///
/// QR Scan é um leitor de QR Code local: nenhuma tela envia ou recebe
/// dados de servidores próprios, não há anúncios e todo o histórico de
/// leituras fica salvo apenas no dispositivo do usuário.
library;

import 'package:flutter/material.dart';

import 'core/theme/cyberpunk_theme.dart';
import 'screens/scanner_screen.dart';

void main() {
  runApp(const QrScanApp());
}

/// Widget raiz do aplicativo.
class QrScanApp extends StatelessWidget {
  const QrScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scan',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.dark,
      home: const ScannerScreen(),
    );
  }
}
