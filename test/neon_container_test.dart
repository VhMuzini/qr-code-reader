// Componentes visuais reutilizáveis: garantem que a decoração neon
// (borda + glow) continue derivando da cor recebida.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/widgets/neon_container.dart';

BoxDecoration decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.byType(Container).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('NeonContainer', () {
    testWidgets('exibe o filho recebido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonContainer(child: Text('conteúdo')),
        ),
      );

      expect(find.text('conteúdo'), findsOneWidget);
    });

    testWidgets('usa a cor informada na borda e no brilho', (tester) async {
      const color = Color(0xFFFF00AA);
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonContainer(
            color: color,
            glowStrength: 0.5,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final decoration = decorationOf(tester);
      expect(decoration.border!.top.color, color.withValues(alpha: 0.8));
      expect(decoration.boxShadow!.single.color, color.withValues(alpha: 0.5));
    });

    testWidgets('aplica padding e raio de borda customizados', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonContainer(
            padding: EdgeInsets.all(4),
            borderRadius: 30,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, const EdgeInsets.all(4));
      expect(
        (container.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(30),
      );
    });
  });
}
