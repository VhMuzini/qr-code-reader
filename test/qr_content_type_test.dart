// Garante que todo tipo de conteúdo tem um rótulo próprio e não vazio —
// o `switch` de [QrContentType.label] precisa continuar exaustivo conforme
// novos tipos forem adicionados ao enum.
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';

void main() {
  group('QrContentType.label', () {
    test('todo tipo tem um rótulo não vazio', () {
      for (final type in QrContentType.values) {
        expect(type.label, isNotEmpty, reason: 'tipo ${type.name} sem rótulo');
      }
    });

    test('rótulos não se repetem entre tipos', () {
      final labels = QrContentType.values.map((t) => t.label).toSet();
      expect(labels, hasLength(QrContentType.values.length));
    });

    test('usa os rótulos em português esperados pela UI', () {
      expect(QrContentType.url.label, 'Link');
      expect(QrContentType.wifi.label, 'Rede Wi-Fi');
      expect(QrContentType.email.label, 'E-mail');
      expect(QrContentType.phone.label, 'Telefone');
      expect(QrContentType.sms.label, 'SMS');
      expect(QrContentType.geo.label, 'Localização');
      expect(QrContentType.contact.label, 'Contato');
      expect(QrContentType.plainText.label, 'Texto');
    });
  });
}
