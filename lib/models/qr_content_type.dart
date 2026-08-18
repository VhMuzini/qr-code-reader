/// Tipos de conteúdo que um QR Code pode representar.
///
/// O padrão QR Code não define "tipos" — ele apenas guarda texto. Porém,
/// existem convenções amplamente usadas (RFC/uri schemes e formatos como
/// o `WIFI:` do Zebra Crossing / vCard) que permitem inferir a intenção
/// do código a partir do seu conteúdo bruto. É isso que [QrContentType]
/// representa: uma classificação feita *depois* da leitura, para decidir
/// como exibir o resultado e quais ações oferecer ao usuário.
library;

enum QrContentType {
  /// Um link da web (`http://`, `https://` ou começando com `www.`).
  url,

  /// Credenciais de rede Wi-Fi no formato `WIFI:T:...;S:...;P:...;;`.
  wifi,

  /// Endereço de e-mail (`mailto:` ou um texto que parece um e-mail).
  email,

  /// Número de telefone (`tel:`).
  phone,

  /// Mensagem de SMS (`sms:` ou `SMSTO:`).
  sms,

  /// Coordenadas geográficas (`geo:latitude,longitude`).
  geo,

  /// Cartão de contato no formato vCard (`BEGIN:VCARD ... END:VCARD`).
  contact,

  /// Qualquer outro texto sem um formato reconhecido.
  plainText;

  /// Rótulo em português exibido para o usuário na tela de resultado.
  String get label => switch (this) {
        QrContentType.url => 'Link',
        QrContentType.wifi => 'Rede Wi-Fi',
        QrContentType.email => 'E-mail',
        QrContentType.phone => 'Telefone',
        QrContentType.sms => 'SMS',
        QrContentType.geo => 'Localização',
        QrContentType.contact => 'Contato',
        QrContentType.plainText => 'Texto',
      };
}
