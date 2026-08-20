/// Construção de URIs seguras a partir de conteúdo lido de QR Code.
library;

/// Monta as URIs usadas pelas ações da tela de resultado.
///
/// O conteúdo de um QR Code é entrada não confiável: quem imprime o
/// código escolhe cada caractere. Interpolar esse texto direto em uma
/// URI permite que um código malicioso mude o significado da ação — por
/// exemplo injetar `?body=`/`&cc=` para que o SMS ou o e-mail vá para
/// outro destinatário do que o mostrado na tela, esconder um código MMI
/// (`*21*...#`, desvio de chamadas) em um `tel:` ou trocar o host de um
/// link com `usuario@` (`https://banco.com@site-falso.com`).
///
/// Por isso cada ação passa por um construtor daqui, que valida os campos
/// e delega a codificação para [Uri]. Quando o conteúdo não é válido para
/// a ação, o retorno é `null` e a interface avisa o usuário em vez de
/// abrir algo inesperado.
class SafeActionUri {
  const SafeActionUri._();

  /// Esquemas que o app aceita abrir. Qualquer outro (`javascript:`,
  /// `intent:`, `file:`, `content:`…) é recusado.
  static const Set<String> allowedSchemes = {
    'http',
    'https',
    'tel',
    'sms',
    'mailto',
    'geo',
  };

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Caracteres aceitos em um número de telefone. `*` e `#` ficam de fora
  /// de propósito: são o que forma códigos MMI/USSD.
  static final RegExp _phoneDisallowed = RegExp(r'[^0-9+()\- ]');

  /// Indica se [uri] pode ser aberto pelo app.
  static bool isAllowed(Uri uri) => allowedSchemes.contains(uri.scheme);

  /// URI de um link da web. Aceita apenas `http`/`https` com host, e
  /// completa com `https://` quando o QR Code traz só `www.algo.com`.
  static Uri? web(String rawValue) {
    var value = rawValue.trim();
    if (value.toLowerCase().startsWith('www.')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        // `https://host-confiavel@host-real/` exibe um host e abre outro.
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  /// URI de discagem para [number], sem caracteres de código MMI/USSD.
  static Uri? phone(String number) {
    final sanitized = number.replaceAll(_phoneDisallowed, '').trim();
    if (!sanitized.contains(RegExp('[0-9]'))) return null;
    return Uri(scheme: 'tel', path: sanitized);
  }

  /// URI de SMS para [number] com [body] já codificado como parâmetro.
  static Uri? sms(String number, String body) {
    final sanitized = number.replaceAll(_phoneDisallowed, '').trim();
    if (!sanitized.contains(RegExp('[0-9]'))) return null;
    return Uri(
      scheme: 'sms',
      path: sanitized,
      queryParameters: body.isEmpty ? null : {'body': body},
    );
  }

  /// URI de e-mail para [address], com assunto e corpo opcionais.
  static Uri? email(String address, {String subject = '', String body = ''}) {
    final trimmed = address.trim();
    if (!_emailRegex.hasMatch(trimmed)) return null;

    final query = {
      if (subject.isNotEmpty) 'subject': subject,
      if (body.isNotEmpty) 'body': body,
    };
    return Uri(
      scheme: 'mailto',
      path: trimmed,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  /// URI do mapa para as coordenadas [latitude]/[longitude], que precisam
  /// ser números dentro da faixa válida.
  static Uri? map(String latitude, String longitude) {
    final lat = double.tryParse(latitude.trim());
    final lng = double.tryParse(longitude.trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    return Uri.https('www.openstreetmap.org', '/', {
      'mlat': '$lat',
      'mlon': '$lng',
    }).replace(fragment: 'map=16/$lat/$lng');
  }
}
