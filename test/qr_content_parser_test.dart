// Testes unitários do parser de conteúdo de QR Code. Cobrem os formatos
// mais comuns encontrados "na vida real" para garantir que a
// classificação e a extração de campos continuem corretas conforme o
// código evolui.
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';
import 'package:qr_code_reader/services/qr_content_parser.dart';

void main() {
  group('QrContentParser', () {
    test('reconhece URLs http/https', () {
      final result = QrContentParser.parse('https://flutter.dev');
      expect(result.type, QrContentType.url);
      expect(result.rawValue, 'https://flutter.dev');
    });

    test('reconhece URLs começando com www.', () {
      final result = QrContentParser.parse('www.exemplo.com.br');
      expect(result.type, QrContentType.url);
    });

    test('reconhece e separa credenciais de Wi-Fi', () {
      final result = QrContentParser.parse(
        r'WIFI:T:WPA;S:MinhaRede;P:senha\;123;H:false;;',
      );
      expect(result.type, QrContentType.wifi);
      expect(result.fields['ssid'], 'MinhaRede');
      expect(result.fields['password'], 'senha;123');
      expect(result.fields['security'], 'WPA');
    });

    test('reconhece número de telefone (tel:)', () {
      final result = QrContentParser.parse('tel:+5511999998888');
      expect(result.type, QrContentType.phone);
      expect(result.fields['number'], '+5511999998888');
    });

    test('reconhece e-mail via mailto:', () {
      final result = QrContentParser.parse(
        'mailto:contato@exemplo.com?subject=Ola&body=Mensagem',
      );
      expect(result.type, QrContentType.email);
      expect(result.fields['address'], 'contato@exemplo.com');
      expect(result.fields['subject'], 'Ola');
    });

    test('reconhece e-mail solto (sem esquema)', () {
      final result = QrContentParser.parse('contato@exemplo.com');
      expect(result.type, QrContentType.email);
    });

    test('reconhece coordenadas geográficas', () {
      final result = QrContentParser.parse('geo:-23.55052,-46.633308');
      expect(result.type, QrContentType.geo);
      expect(result.fields['latitude'], '-23.55052');
      expect(result.fields['longitude'], '-46.633308');
    });

    test('reconhece SMSTO', () {
      final result = QrContentParser.parse('SMSTO:+551199999999:Ola mundo');
      expect(result.type, QrContentType.sms);
      expect(result.fields['number'], '+551199999999');
      expect(result.fields['body'], 'Ola mundo');
    });

    test('reconhece vCard e extrai nome/telefone/email', () {
      final result = QrContentParser.parse(
        'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'N:Silva;Joao;;;\n'
        'TEL;TYPE=CELL:+5511988887777\n'
        'EMAIL:joao@exemplo.com\n'
        'END:VCARD',
      );
      expect(result.type, QrContentType.contact);
      expect(result.fields['name'], 'Silva Joao');
      expect(result.fields['phone'], '+5511988887777');
      expect(result.fields['email'], 'joao@exemplo.com');
    });

    test('cai para texto simples quando não reconhece o formato', () {
      final result = QrContentParser.parse('Apenas um texto qualquer');
      expect(result.type, QrContentType.plainText);
    });
  });
}
