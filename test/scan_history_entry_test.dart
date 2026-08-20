// Serialização do histórico: o formato salvo em disco precisa continuar
// legível por versões futuras, inclusive quando o registro trouxer um tipo
// desconhecido.
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';
import 'package:qr_code_reader/models/scan_history_entry.dart';

void main() {
  group('ScanHistoryEntry', () {
    final entry = ScanHistoryEntry(
      id: '1700000000000000',
      rawValue: 'https://flutter.dev',
      type: QrContentType.url,
      scannedAt: DateTime.utc(2024, 5, 4, 3, 2, 1),
    );

    test('toJson usa o nome do tipo e data ISO-8601', () {
      expect(entry.toJson(), {
        'id': '1700000000000000',
        'rawValue': 'https://flutter.dev',
        'type': 'url',
        'scannedAt': '2024-05-04T03:02:01.000Z',
      });
    });

    test('fromJson reconstrói a entrada salva por toJson', () {
      final restored = ScanHistoryEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.rawValue, entry.rawValue);
      expect(restored.type, entry.type);
      expect(restored.scannedAt, entry.scannedAt);
    });

    test('tipo desconhecido cai para texto simples', () {
      final restored = ScanHistoryEntry.fromJson({
        'id': 'x',
        'rawValue': 'algo',
        'type': 'tipoQueAindaNaoExiste',
        'scannedAt': '2024-05-04T03:02:01.000Z',
      });
      expect(restored.type, QrContentType.plainText);
    });

    test('lança quando campos obrigatórios estão ausentes', () {
      expect(
        () => ScanHistoryEntry.fromJson({'id': 'x'}),
        throwsA(anything),
      );
    });
  });
}
