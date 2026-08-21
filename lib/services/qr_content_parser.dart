/// Interpretação do texto bruto lido de um QR Code.
library;

import '../models/parsed_qr_content.dart';
import '../models/qr_content_type.dart';

/// Analisa o texto bruto retornado pelo scanner e o transforma em um
/// [ParsedQrContent] com um tipo reconhecido e campos já separados.
///
/// Esta classe não depende de Flutter (apenas `dart:core`), o que a torna
/// fácil de testar isoladamente (ver `test/`).
class QrContentParser {
  const QrContentParser._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  /// Interpreta [rawValue] e retorna o conteúdo já classificado.
  static ParsedQrContent parse(String rawValue) {
    final value = rawValue.trim();
    final upper = value.toUpperCase();

    if (upper.startsWith('WIFI:')) {
      return _parseWifi(value);
    }
    if (upper.startsWith('BEGIN:VCARD')) {
      return _parseVCard(value);
    }
    if (upper.startsWith('GEO:')) {
      return _parseGeo(value);
    }
    if (upper.startsWith('MAILTO:')) {
      return _parseEmail(_withoutScheme(value, 'mailto:'));
    }
    if (upper.startsWith('MATMSG:')) {
      return _parseMatMsg(value);
    }
    if (upper.startsWith('TEL:')) {
      return ParsedQrContent(
        rawValue: value,
        type: QrContentType.phone,
        fields: {'number': _withoutScheme(value, 'tel:')},
      );
    }
    if (upper.startsWith('SMSTO:') || upper.startsWith('SMS:')) {
      return _parseSms(value);
    }
    if (upper.startsWith('HTTP://') ||
        upper.startsWith('HTTPS://') ||
        upper.startsWith('WWW.')) {
      return ParsedQrContent(rawValue: value, type: QrContentType.url);
    }
    if (_emailRegex.hasMatch(value)) {
      return ParsedQrContent(
        rawValue: value,
        type: QrContentType.email,
        fields: {'address': value},
      );
    }

    return ParsedQrContent(rawValue: value, type: QrContentType.plainText);
  }

  // -------------------------------------------------------------------
  // WIFI:T:WPA;S:MinhaRede;P:minhaSenha;H:false;;
  // -------------------------------------------------------------------
  static ParsedQrContent _parseWifi(String value) {
    final fields = _splitFields(_withoutScheme(value, 'WIFI:'));
    return ParsedQrContent(
      rawValue: value,
      type: QrContentType.wifi,
      fields: {
        'ssid': fields['S'] ?? '',
        'password': fields['P'] ?? '',
        'security': fields['T'] ?? 'nopass',
        'hidden': fields['H'] ?? 'false',
      },
    );
  }

  // -------------------------------------------------------------------
  // BEGIN:VCARD\nVERSION:3.0\nN:Sobrenome;Nome\nTEL:...\nEMAIL:...\nEND:VCARD
  // -------------------------------------------------------------------
  static ParsedQrContent _parseVCard(String value) {
    String? name;
    String? phone;
    String? email;

    for (final rawLine in value.split(RegExp(r'\r\n|\n|\r'))) {
      final line = rawLine.trim();
      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) continue;

      // Propriedades vCard podem ter parâmetros, ex.: "TEL;TYPE=CELL:123".
      // Usamos apenas a parte antes do ';' para identificar a propriedade.
      final property = line.substring(0, separatorIndex).split(';').first.toUpperCase();
      final contentValue = line.substring(separatorIndex + 1).trim();

      switch (property) {
        case 'FN':
          name ??= contentValue;
        case 'N':
          // Formato N: Sobrenome;Nome;NomeDoMeio;Prefixo;Sufixo
          name ??= contentValue.split(';').where((p) => p.isNotEmpty).join(' ');
        case 'TEL':
          phone ??= contentValue;
        case 'EMAIL':
          email ??= contentValue;
      }
    }

    return ParsedQrContent(
      rawValue: value,
      type: QrContentType.contact,
      fields: {
        if (name != null && name.isNotEmpty) 'name': name,
        'phone': ?phone,
        'email': ?email,
      },
    );
  }

  // -------------------------------------------------------------------
  // geo:latitude,longitude[,altitude]
  // -------------------------------------------------------------------
  static ParsedQrContent _parseGeo(String value) {
    final body = _withoutScheme(value, 'geo:');
    final parts = body.split(RegExp('[,;]'));
    return ParsedQrContent(
      rawValue: value,
      type: QrContentType.geo,
      fields: {
        'latitude': _partAt(parts, 0),
        'longitude': _partAt(parts, 1),
      },
    );
  }

  // -------------------------------------------------------------------
  // mailto:endereco@dominio.com?subject=Assunto&body=Mensagem
  // -------------------------------------------------------------------
  static ParsedQrContent _parseEmail(String afterScheme) {
    final uri = Uri.tryParse('mailto:$afterScheme');
    final address = uri?.path ?? afterScheme.split('?').first;
    return ParsedQrContent(
      rawValue: 'mailto:$afterScheme',
      type: QrContentType.email,
      fields: {
        'address': address,
        if (uri?.queryParameters['subject'] != null)
          'subject': uri!.queryParameters['subject']!,
        if (uri?.queryParameters['body'] != null)
          'body': uri!.queryParameters['body']!,
      },
    );
  }

  // -------------------------------------------------------------------
  // MATMSG:TO:endereco@dominio.com;SUB:Assunto;BODY:Mensagem;;
  // -------------------------------------------------------------------
  static ParsedQrContent _parseMatMsg(String value) {
    final fields = _splitFields(_withoutScheme(value, 'MATMSG:'));
    return ParsedQrContent(
      rawValue: value,
      type: QrContentType.email,
      fields: {
        'address': fields['TO'] ?? '',
        if (fields['SUB'] != null) 'subject': fields['SUB']!,
        if (fields['BODY'] != null) 'body': fields['BODY']!,
      },
    );
  }

  // -------------------------------------------------------------------
  // SMSTO:numero:mensagem   ou   sms:numero?body=mensagem
  // -------------------------------------------------------------------
  static ParsedQrContent _parseSms(String value) {
    final upper = value.toUpperCase();
    if (upper.startsWith('SMSTO:')) {
      final body = _withoutScheme(value, 'SMSTO:');
      final parts = body.split(':');
      return ParsedQrContent(
        rawValue: value,
        type: QrContentType.sms,
        fields: {
          'number': _partAt(parts, 0),
          'body': parts.length > 1 ? parts.sublist(1).join(':') : '',
        },
      );
    }

    // sms:numero?body=mensagem
    final withoutScheme = _withoutScheme(value, 'sms:');
    final uri = Uri.tryParse('sms:$withoutScheme');
    final number = uri?.path ?? withoutScheme.split('?').first;
    return ParsedQrContent(
      rawValue: value,
      type: QrContentType.sms,
      fields: {
        'number': number,
        'body': uri?.queryParameters['body'] ?? '',
      },
    );
  }

  /// Remove o esquema já reconhecido sem alterar o restante do valor.
  ///
  /// A comparação de caixa acontece antes, em [parse] ou no parser
  /// específico; aqui usamos apenas o comprimento para preservar o texto.
  static String _withoutScheme(String value, String scheme) {
    return value.substring(scheme.length);
  }

  /// Retorna a parte na posição pedida ou uma string vazia quando ela não
  /// existe, mantendo seguros os parsers de formatos incompletos.
  static String _partAt(List<String> parts, int index) {
    return index < parts.length ? parts[index] : '';
  }

  /// Divide um trecho no formato `CHAVE:valor;CHAVE2:valor2;;` em um mapa,
  /// tratando o `\` usado por essas convenções para escapar `:`, `;` e `,`
  /// dentro dos valores (ex.: senhas de Wi-Fi com esses caracteres).
  static Map<String, String> _splitFields(String body) {
    final result = <String, String>{};
    final buffer = StringBuffer();
    String? currentKey;
    var escaped = false;

    void commit() {
      if (currentKey != null) {
        result[currentKey!] = buffer.toString();
      }
      buffer.clear();
      currentKey = null;
    }

    for (final char in body.split('')) {
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      switch (char) {
        case r'\':
          escaped = true;
        case ':' when currentKey == null:
          currentKey = buffer.toString();
          buffer.clear();
        case ';':
          commit();
        default:
          buffer.write(char);
      }
    }
    commit();

    return result;
  }
}
