// Testes das URIs construídas a partir do conteúdo (não confiável) de um
// QR Code. O foco aqui é o abuso: conteúdo que tenta trocar o destino da
// ação ou usar um esquema que o app não deveria abrir.
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/services/safe_action_uri.dart';

void main() {
  group('SafeActionUri.web', () {
    test('aceita http/https e completa endereços com www.', () {
      expect(SafeActionUri.web('https://flutter.dev').toString(),
          'https://flutter.dev');
      expect(SafeActionUri.web('www.exemplo.com.br').toString(),
          'https://www.exemplo.com.br');
    });

    test('recusa esquemas fora de http/https', () {
      expect(SafeActionUri.web('javascript:alert(1)'), isNull);
      expect(SafeActionUri.web('file:///etc/passwd'), isNull);
      expect(SafeActionUri.web('intent://x#Intent;end'), isNull);
    });

    test('recusa link que esconde o host real em userinfo', () {
      expect(SafeActionUri.web('https://banco.com@site-falso.com'), isNull);
    });
  });

  group('SafeActionUri.phone', () {
    test('mantém apenas caracteres de número discável', () {
      expect(SafeActionUri.phone('+55 (11) 99999-8888').toString(),
          'tel:+55%20(11)%2099999-8888');
    });

    test('remove caracteres de código MMI/USSD', () {
      expect(SafeActionUri.phone('*21*5511999998888#').toString(),
          'tel:215511999998888');
    });

    test('recusa número sem nenhum dígito', () {
      expect(SafeActionUri.phone('***'), isNull);
    });
  });

  group('SafeActionUri.sms', () {
    test('codifica o corpo em vez de deixá-lo virar novos parâmetros', () {
      final uri = SafeActionUri.sms('+5511999998888', 'oi&body=outro')!;
      expect(uri.scheme, 'sms');
      expect(uri.path, '+5511999998888');
      expect(uri.queryParameters, {'body': 'oi&body=outro'});
    });

    test('número não pode injetar parâmetros extras', () {
      final uri = SafeActionUri.sms('+5511999998888?body=golpe', '')!;
      expect(uri.queryParameters, isEmpty);
      expect(uri.path, '+5511999998888');
    });
  });

  group('SafeActionUri.email', () {
    test('monta mailto com assunto e corpo codificados', () {
      final uri = SafeActionUri.email(
        'contato@exemplo.com',
        subject: 'Olá',
        body: 'texto&cc=terceiro@exemplo.com',
      )!;
      expect(uri.path, 'contato@exemplo.com');
      expect(uri.queryParameters['cc'], isNull);
      expect(uri.queryParameters['body'], 'texto&cc=terceiro@exemplo.com');
    });

    test('recusa endereço inválido', () {
      expect(SafeActionUri.email('nao-e-email'), isNull);
      expect(SafeActionUri.email('a@b.com?cc=c@d.com'), isNull);
    });
  });

  group('SafeActionUri.map', () {
    test('monta o link do mapa para coordenadas válidas', () {
      final uri = SafeActionUri.map('-23.55052', '-46.633308')!;
      expect(uri.host, 'www.openstreetmap.org');
      expect(uri.queryParameters['mlat'], '-23.55052');
      expect(uri.fragment, 'map=16/-23.55052/-46.633308');
    });

    test('recusa coordenadas não numéricas ou fora de faixa', () {
      expect(SafeActionUri.map('abc', '10'), isNull);
      expect(SafeActionUri.map('91', '10'), isNull);
      expect(SafeActionUri.map('10', '181'), isNull);
    });
  });

  test('isAllowed cobre apenas os esquemas esperados', () {
    expect(SafeActionUri.isAllowed(Uri.parse('https://a.com')), isTrue);
    expect(SafeActionUri.isAllowed(Uri.parse('tel:123')), isTrue);
    expect(SafeActionUri.isAllowed(Uri.parse('content://x/y')), isFalse);
  });
}
