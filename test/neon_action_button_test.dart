// Botão de ação usado na tela de resultado: precisa mostrar ícone +
// rótulo e disparar o callback ao ser tocado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/widgets/neon_action_button.dart';

void main() {
  group('NeonActionButton', () {
    testWidgets('mostra ícone e rótulo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonActionButton(
              icon: Icons.copy_rounded,
              label: 'Copiar',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
    });

    testWidgets('chama onPressed ao ser tocado', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonActionButton(
              icon: Icons.share_rounded,
              label: 'Compartilhar',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonActionButton));
      expect(taps, 1);
    });

    testWidgets('pinta ícone, texto e borda com a cor informada',
        (tester) async {
      const color = Color(0xFF39FF14);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonActionButton(
              icon: Icons.call_rounded,
              label: 'Ligar',
              color: color,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.widget<Icon>(find.byIcon(Icons.call_rounded)).color, color);
      expect(tester.widget<Text>(find.text('Ligar')).style!.color, color);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, color.withValues(alpha: 0.7));
    });
  });
}
