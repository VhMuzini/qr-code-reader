/// Persistência local do histórico de leituras.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_history_entry.dart';

/// Guarda e recupera o histórico de leituras usando [SharedPreferences].
///
/// Não há nenhuma chamada de rede aqui: tudo fica em um arquivo local
/// gerenciado pelo sistema operacional, respeitando a proposta do app de
/// funcionar 100% offline e sem coletar dados do usuário.
///
/// O histórico é guardado como uma lista JSON sob uma única chave. Para um
/// leitor de QR Code pessoal isso é suficiente — não há necessidade de um
/// banco de dados completo (ex.: sqlite) para esse volume de dados.
class ScanHistoryService {
  ScanHistoryService();

  static const String _storageKey = 'qr_scan_history_v1';

  /// Número máximo de leituras mantidas no histórico. Leituras mais
  /// antigas que essa quantidade são descartadas automaticamente ao
  /// salvar uma nova, para o armazenamento não crescer indefinidamente.
  static const int maxEntries = 200;

  /// Retorna o histórico salvo, do mais recente para o mais antigo.
  Future<List<ScanHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final entries = <ScanHistoryEntry>[];
    for (final item in raw) {
      try {
        entries.add(ScanHistoryEntry.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        ));
      } catch (_) {
        // Ignora entradas corrompidas em vez de derrubar o histórico
        // inteiro por causa de um único registro inválido.
        continue;
      }
    }

    entries.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return entries;
  }

  /// Adiciona [entry] ao início do histórico e persiste a lista.
  Future<void> addEntry(ScanHistoryEntry entry) async {
    final current = await loadHistory();
    final updated = [entry, ...current].take(maxEntries).toList();
    await _saveAll(updated);
  }

  /// Remove uma única entrada pelo [id].
  Future<void> removeEntry(String id) async {
    final current = await loadHistory();
    current.removeWhere((e) => e.id == id);
    await _saveAll(current);
  }

  /// Apaga todo o histórico salvo.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<ScanHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}
