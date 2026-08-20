// Tela de histórico: estado vazio, listagem, reabertura de uma leitura,
// remoção por arraste e limpeza total (com confirmação).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';
import 'package:qr_code_reader/models/scan_history_entry.dart';
import 'package:qr_code_reader/screens/history_screen.dart';
import 'package:qr_code_reader/screens/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storageKey = 'qr_scan_history_v1';

  String encoded(
    String id,
    String rawValue,
    QrContentType type,
    DateTime scannedAt,
  ) {
    return jsonEncode(
      ScanHistoryEntry(
        id: id,
        rawValue: rawValue,
        type: type,
        scannedAt: scannedAt,
      ).toJson(),
    );
  }

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    await tester.pumpAndSettle();
  }

  Future<List<String>?> storedRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mostra indicador de carregamento antes do histórico chegar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('mostra estado vazio quando não há leituras', (tester) async {
    await pumpHistory(tester);

    expect(find.text('Nenhuma leitura ainda'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
  });

  testWidgets('lista as leituras com tipo, data e ícone', (tester) async {
    SharedPreferences.setMockInitialValues({
      storageKey: [
        encoded('1', 'https://flutter.dev', QrContentType.url,
            DateTime(2024, 3, 9, 7, 5)),
      ],
    });

    await pumpHistory(tester);

    expect(find.text('https://flutter.dev'), findsOneWidget);
    expect(find.text('Link · 09/03/2024 07:05'), findsOneWidget);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
  });

  testWidgets('mostra as leituras mais recentes primeiro', (tester) async {
    SharedPreferences.setMockInitialValues({
      storageKey: [
        encoded('1', 'antiga', QrContentType.plainText, DateTime(2024, 1, 1)),
        encoded('2', 'recente', QrContentType.plainText, DateTime(2024, 6, 1)),
      ],
    });

    await pumpHistory(tester);

    final antiga = tester.getTopLeft(find.text('antiga'));
    final recente = tester.getTopLeft(find.text('recente'));
    expect(recente.dy, lessThan(antiga.dy));
  });

  testWidgets('tocar em uma leitura abre a tela de resultado reinterpretada',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      storageKey: [
        encoded('1', 'tel:+5511999998888', QrContentType.phone,
            DateTime(2024, 1, 1)),
      ],
    });

    await pumpHistory(tester);
    await tester.tap(find.text('tel:+5511999998888'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('TELEFONE'), findsOneWidget);
    expect(find.text('tel:+5511999998888'), findsWidgets);
  });

  testWidgets('arrastar para o lado remove a leitura do armazenamento',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      storageKey: [
        encoded('1', 'para apagar', QrContentType.plainText,
            DateTime(2024, 1, 1)),
        encoded('2', 'para manter', QrContentType.plainText,
            DateTime(2024, 2, 1)),
      ],
    });

    await pumpHistory(tester);
    await tester.drag(find.text('para apagar'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('para apagar'), findsNothing);
    expect(find.text('para manter'), findsOneWidget);
    expect(await storedRaw(), hasLength(1));
  });

  group('limpar tudo', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        storageKey: [
          encoded('1', 'leitura', QrContentType.plainText, DateTime(2024, 1, 1)),
        ],
      });
    });

    testWidgets('cancelar mantém o histórico intacto', (tester) async {
      await pumpHistory(tester);
      await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('leitura'), findsOneWidget);
      expect(await storedRaw(), hasLength(1));
    });

    testWidgets('confirmar apaga tudo e mostra o estado vazio',
        (tester) async {
      await pumpHistory(tester);
      await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Limpar'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma leitura ainda'), findsOneWidget);
      expect(await storedRaw(), isNull);
    });
  });
}
