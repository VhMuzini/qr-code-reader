// Persistência do histórico. Usamos os valores iniciais "mockados" do
// shared_preferences para exercitar o serviço sem depender de um
// dispositivo real.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';
import 'package:qr_code_reader/models/scan_history_entry.dart';
import 'package:qr_code_reader/services/scan_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScanHistoryEntry entryAt(DateTime when, {String? id, String? rawValue}) {
  return ScanHistoryEntry(
    id: id ?? when.microsecondsSinceEpoch.toString(),
    rawValue: rawValue ?? 'valor ${when.toIso8601String()}',
    type: QrContentType.plainText,
    scannedAt: when,
  );
}

void main() {
  const storageKey = 'qr_scan_history_v1';
  late ScanHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ScanHistoryService();
  });

  Future<List<String>?> storedRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey);
  }

  group('loadHistory', () {
    test('retorna vazio quando nada foi salvo', () async {
      expect(await service.loadHistory(), isEmpty);
    });

    test('retorna vazio quando a lista salva está vazia', () async {
      SharedPreferences.setMockInitialValues({storageKey: <String>[]});
      expect(await service.loadHistory(), isEmpty);
    });

    test('ordena do mais recente para o mais antigo', () async {
      SharedPreferences.setMockInitialValues({
        storageKey: [
          jsonEncode(entryAt(DateTime.utc(2024, 1, 1), id: 'antigo').toJson()),
          jsonEncode(entryAt(DateTime.utc(2024, 3, 1), id: 'novo').toJson()),
          jsonEncode(entryAt(DateTime.utc(2024, 2, 1), id: 'meio').toJson()),
        ],
      });

      final entries = await service.loadHistory();
      expect(entries.map((e) => e.id), ['novo', 'meio', 'antigo']);
    });

    test('ignora entradas corrompidas sem perder as válidas', () async {
      SharedPreferences.setMockInitialValues({
        storageKey: [
          'isso não é json',
          jsonEncode({'id': 'sem os outros campos'}),
          jsonEncode(entryAt(DateTime.utc(2024, 1, 1), id: 'ok').toJson()),
        ],
      });

      final entries = await service.loadHistory();
      expect(entries.map((e) => e.id), ['ok']);
    });
  });

  group('addEntry', () {
    test('salva a entrada e a devolve na leitura seguinte', () async {
      await service.addEntry(
        entryAt(DateTime.utc(2024, 1, 1), id: 'a', rawValue: 'tel:123'),
      );

      final entries = await service.loadHistory();
      expect(entries, hasLength(1));
      expect(entries.single.rawValue, 'tel:123');
    });

    test('coloca a leitura mais recente no topo', () async {
      await service.addEntry(entryAt(DateTime.utc(2024, 1, 1), id: 'a'));
      await service.addEntry(entryAt(DateTime.utc(2024, 2, 1), id: 'b'));

      final entries = await service.loadHistory();
      expect(entries.map((e) => e.id), ['b', 'a']);
    });

    test('descarta as leituras além do limite máximo', () async {
      SharedPreferences.setMockInitialValues({
        storageKey: List.generate(
          ScanHistoryService.maxEntries,
          (i) => jsonEncode(
            entryAt(DateTime.utc(2024, 1, 1).add(Duration(minutes: i)),
                    id: 'antiga$i')
                .toJson(),
          ),
        ),
      });

      await service.addEntry(entryAt(DateTime.utc(2025, 1, 1), id: 'nova'));

      final entries = await service.loadHistory();
      expect(entries, hasLength(ScanHistoryService.maxEntries));
      expect(entries.first.id, 'nova');
      // A leitura mais antiga é a que sai da lista.
      expect(entries.map((e) => e.id), isNot(contains('antiga0')));
    });
  });

  group('removeEntry', () {
    test('remove apenas a entrada com o id informado', () async {
      await service.addEntry(entryAt(DateTime.utc(2024, 1, 1), id: 'a'));
      await service.addEntry(entryAt(DateTime.utc(2024, 2, 1), id: 'b'));

      await service.removeEntry('a');

      final entries = await service.loadHistory();
      expect(entries.map((e) => e.id), ['b']);
    });

    test('não altera nada quando o id não existe', () async {
      await service.addEntry(entryAt(DateTime.utc(2024, 1, 1), id: 'a'));

      await service.removeEntry('inexistente');

      expect((await service.loadHistory()).map((e) => e.id), ['a']);
    });
  });

  group('clearAll', () {
    test('apaga a chave de armazenamento inteira', () async {
      await service.addEntry(entryAt(DateTime.utc(2024, 1, 1), id: 'a'));
      expect(await storedRaw(), isNotNull);

      await service.clearAll();

      expect(await storedRaw(), isNull);
      expect(await service.loadHistory(), isEmpty);
    });
  });
}
