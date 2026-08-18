// Teste de widget básico: garante que o app sobe sem erros e que a tela
// inicial (Scanner) é exibida com seu título.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_code_reader/main.dart';

void main() {
  testWidgets('App inicia mostrando a tela de leitura', (tester) async {
    await tester.pumpWidget(const QrScanApp());

    expect(find.text('QR SCAN'), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
  });
}
