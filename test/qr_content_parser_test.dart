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

    test('ignora espaços em volta do conteúdo', () {
      final result = QrContentParser.parse('   https://flutter.dev  \n');
      expect(result.type, QrContentType.url);
      expect(result.rawValue, 'https://flutter.dev');
    });

    test('reconhece esquemas escritos em maiúsculas', () {
      expect(QrContentParser.parse('HTTP://EXEMPLO.COM').type,
          QrContentType.url);
      expect(QrContentParser.parse('TEL:+551133334444').type,
          QrContentType.phone);
      expect(QrContentParser.parse('MAILTO:contato@exemplo.com').type,
          QrContentType.email);
    });

    test('texto vazio é tratado como texto simples', () {
      final result = QrContentParser.parse('   ');
      expect(result.type, QrContentType.plainText);
      expect(result.rawValue, isEmpty);
    });

    group('Wi-Fi', () {
      test('usa padrões quando segurança e visibilidade não vêm no código', () {
        final result = QrContentParser.parse('WIFI:S:RedeAberta;;');
        expect(result.fields['ssid'], 'RedeAberta');
        expect(result.fields['password'], isEmpty);
        expect(result.fields['security'], 'nopass');
        expect(result.fields['hidden'], 'false');
      });

      test('desescapa os caracteres reservados dentro dos valores', () {
        final result = QrContentParser.parse(
          r'WIFI:T:WPA;S:Rede\:Casa;P:a\;b\,c\\d;H:true;;',
        );
        expect(result.fields['ssid'], 'Rede:Casa');
        expect(result.fields['password'], r'a;b,c\d');
        expect(result.fields['hidden'], 'true');
      });
    });

    group('e-mail', () {
      test('mailto: sem parâmetros extrai apenas o endereço', () {
        final result = QrContentParser.parse('mailto:contato@exemplo.com');
        expect(result.fields['address'], 'contato@exemplo.com');
        expect(result.fields.containsKey('subject'), isFalse);
        expect(result.fields.containsKey('body'), isFalse);
      });

      test('reconhece o formato MATMSG', () {
        final result = QrContentParser.parse(
          'MATMSG:TO:contato@exemplo.com;SUB:Assunto;BODY:Mensagem;;',
        );
        expect(result.type, QrContentType.email);
        expect(result.fields['address'], 'contato@exemplo.com');
        expect(result.fields['subject'], 'Assunto');
        expect(result.fields['body'], 'Mensagem');
      });

      test('MATMSG sem assunto/corpo não inventa os campos', () {
        final result = QrContentParser.parse('MATMSG:TO:a@b.com;;');
        expect(result.fields['address'], 'a@b.com');
        expect(result.fields.containsKey('subject'), isFalse);
        expect(result.fields.containsKey('body'), isFalse);
      });

      test('texto que não é um endereço válido não vira e-mail', () {
        expect(QrContentParser.parse('sem-arroba.com').type,
            QrContentType.plainText);
        expect(QrContentParser.parse('a@b').type, QrContentType.plainText);
        expect(QrContentParser.parse('escreva para a@b.com hoje').type,
            QrContentType.plainText);
      });
    });

    group('SMS', () {
      test('sms: usa o parâmetro body como mensagem', () {
        final result = QrContentParser.parse('sms:+551199999999?body=Ola');
        expect(result.type, QrContentType.sms);
        expect(result.fields['number'], '+551199999999');
        expect(result.fields['body'], 'Ola');
      });

      test('sms: sem mensagem devolve corpo vazio', () {
        final result = QrContentParser.parse('sms:+551199999999');
        expect(result.fields['number'], '+551199999999');
        expect(result.fields['body'], isEmpty);
      });

      test('SMSTO sem mensagem devolve corpo vazio', () {
        final result = QrContentParser.parse('SMSTO:+551199999999');
        expect(result.fields['number'], '+551199999999');
        expect(result.fields['body'], isEmpty);
      });

      test('SMSTO mantém ":" que fizer parte da mensagem', () {
        final result = QrContentParser.parse('SMSTO:123:aviso: chegou');
        expect(result.fields['number'], '123');
        expect(result.fields['body'], 'aviso: chegou');
      });
    });

    group('localização', () {
      test('aceita ";" como separador e ignora a altitude', () {
        final result = QrContentParser.parse('geo:-23.55;-46.63;800');
        expect(result.fields['latitude'], '-23.55');
        expect(result.fields['longitude'], '-46.63');
      });

      test('longitude ausente vira campo vazio', () {
        final result = QrContentParser.parse('geo:-23.55');
        expect(result.fields['latitude'], '-23.55');
        expect(result.fields['longitude'], isEmpty);
      });
    });

    group('vCard', () {
      test('prefere FN quando presente e aceita CRLF', () {
        final result = QrContentParser.parse(
          'BEGIN:VCARD\r\n'
          'FN:Joao da Silva\r\n'
          'N:Silva;Joao\r\n'
          'END:VCARD',
        );
        expect(result.fields['name'], 'Joao da Silva');
      });

      test('ignora linhas sem ":" e propriedades desconhecidas', () {
        final result = QrContentParser.parse(
          'BEGIN:VCARD\n'
          'linha sem separador\n'
          'ORG:Empresa\n'
          'TEL:111\n'
          'TEL:222\n'
          'END:VCARD',
        );
        expect(result.type, QrContentType.contact);
        // Apenas o primeiro valor de cada propriedade é considerado.
        expect(result.fields['phone'], '111');
        expect(result.fields.containsKey('name'), isFalse);
        expect(result.fields.containsKey('email'), isFalse);
      });
    });
  });
}
