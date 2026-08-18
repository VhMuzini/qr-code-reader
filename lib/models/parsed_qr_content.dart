/// Representação estruturada do conteúdo de um QR Code já interpretado.
library;

import 'qr_content_type.dart';

/// Resultado da análise de um QR Code: o texto bruto lido pela câmera,
/// o [type] inferido a partir desse texto e, quando fizer sentido,
/// campos extras já separados (ex.: SSID e senha de uma rede Wi-Fi).
///
/// [fields] guarda pares chave/valor específicos de cada tipo, para que a
/// tela de resultado consiga montar uma exibição amigável sem precisar
/// re-interpretar o texto bruto. As chaves usadas por tipo são:
///
/// * [QrContentType.wifi]: `ssid`, `password`, `security`, `hidden`.
/// * [QrContentType.contact]: `name`, `phone`, `email`.
/// * [QrContentType.geo]: `latitude`, `longitude`.
/// * [QrContentType.email]: `address`, `subject`, `body`.
/// * [QrContentType.sms] / [QrContentType.phone]: `number`, `body`.
class ParsedQrContent {
  const ParsedQrContent({
    required this.rawValue,
    required this.type,
    this.fields = const {},
  });

  /// Texto exatamente como veio do decodificador de QR Code, sem nenhuma
  /// transformação. É sempre o que salvamos no histórico, para que a
  /// reinterpretação futura não perca informação.
  final String rawValue;

  /// Categoria inferida a partir de [rawValue].
  final QrContentType type;

  /// Campos adicionais extraídos de [rawValue], específicos de [type].
  final Map<String, String> fields;
}
