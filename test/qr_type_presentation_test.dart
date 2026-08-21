// A apresentação (ícone/cor) é usada tanto na tela de resultado quanto no
// histórico; estes testes protegem a exaustividade dos `switch` e o
// mapeamento das cores de destaque.
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/core/qr_type_presentation.dart';
import 'package:qr_code_reader/core/theme/app_colors.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';

void main() {
  group('QrContentTypePresentation', () {
    test('todo tipo tem ícone e cor definidos', () {
      for (final type in QrContentType.values) {
        expect(type.icon, isNotNull, reason: 'tipo ${type.name} sem ícone');
        expect(type.accentColor, isNotNull, reason: 'tipo ${type.name} sem cor');
      }
    });

    test('ícones são distintos entre tipos', () {
      final icons = QrContentType.values.map((t) => t.icon).toSet();
      expect(icons, hasLength(QrContentType.values.length));
    });

    test('usa as cores neon esperadas por tipo', () {
      expect(QrContentType.url.accentColor, AppColors.neonCyan);
      expect(QrContentType.wifi.accentColor, AppColors.neonGreen);
      expect(QrContentType.email.accentColor, AppColors.neonMagenta);
      expect(QrContentType.phone.accentColor, AppColors.neonGreen);
      expect(QrContentType.sms.accentColor, AppColors.neonMagenta);
      expect(QrContentType.geo.accentColor, AppColors.neonPurple);
      expect(QrContentType.contact.accentColor, AppColors.neonPurple);
      expect(QrContentType.plainText.accentColor, AppColors.neonCyan);
    });
  });
}
