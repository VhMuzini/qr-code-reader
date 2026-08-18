/// Modelo de uma entrada salva no histórico de leituras.
library;

import 'qr_content_type.dart';

/// Um registro do histórico local de leituras de QR Code.
///
/// Guardamos apenas o essencial para poder reconstruir a tela de
/// resultado depois (o texto bruto e o tipo já classificado), além de
/// metadados de exibição (data/hora). Tudo fica salvo somente no
/// dispositivo do usuário — o app não envia nada para nenhum servidor.
class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.id,
    required this.rawValue,
    required this.type,
    required this.scannedAt,
  });

  /// Identificador único da entrada (baseado no timestamp da leitura).
  ///
  /// Usado como `key` de widgets de lista e para permitir remover um item
  /// específico do histórico.
  final String id;

  /// Conteúdo bruto decodificado do QR Code.
  final String rawValue;

  /// Tipo de conteúdo já classificado no momento da leitura.
  final QrContentType type;

  /// Data e hora em que a leitura foi feita.
  final DateTime scannedAt;

  /// Converte esta entrada em um mapa serializável em JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'rawValue': rawValue,
        'type': type.name,
        'scannedAt': scannedAt.toIso8601String(),
      };

  /// Reconstrói uma entrada a partir do mapa produzido por [toJson].
  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      id: json['id'] as String,
      rawValue: json['rawValue'] as String,
      type: QrContentType.values.firstWhere(
        (t) => t.name == json['type'],
        // Se um tipo desconhecido chegar a ser salvo por uma versão
        // futura do app, caímos de volta para texto simples em vez de
        // quebrar a leitura do histórico inteiro.
        orElse: () => QrContentType.plainText,
      ),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}
