/// Tela com o histórico local de leituras.
library;

import 'package:flutter/material.dart';

import '../core/qr_type_presentation.dart';
import '../core/theme/app_colors.dart';
import '../models/scan_history_entry.dart';
import '../services/qr_content_parser.dart';
import '../services/scan_history_service.dart';
import 'result_screen.dart';

/// Lista as leituras anteriores, guardadas apenas localmente no
/// dispositivo (ver [ScanHistoryService]).
///
/// Permite reabrir cada leitura na [ResultScreen], remover itens
/// individualmente (arrastando para o lado) ou limpar tudo de uma vez.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScanHistoryService _historyService = ScanHistoryService();
  late Future<List<ScanHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.loadHistory();
  }

  void _reload() {
    setState(() => _historyFuture = _historyService.loadHistory());
  }

  Future<void> _removeEntry(ScanHistoryEntry entry) async {
    await _historyService.removeEntry(entry.id);
    _reload();
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: const Text(
          'Todas as leituras salvas neste dispositivo serão apagadas. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAll();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTÓRICO'),
        actions: [
          IconButton(
            tooltip: 'Limpar tudo',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<ScanHistoryEntry>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            );
          }

          final entries = snapshot.data ?? const [];
          if (entries.isEmpty) {
            return const _EmptyHistory();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryTile(
                entry: entry,
                onTap: () {
                  final parsed = QrContentParser.parse(entry.rawValue);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResultScreen(content: parsed),
                    ),
                  );
                },
                onDismissed: () => _removeEntry(entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'Nenhuma leitura ainda',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Os QR Codes que você ler aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDismissed,
  });

  final ScanHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final color = entry.type.accentColor;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonRed),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.neonRed),
      ),
      onDismissed: (_) => onDismissed(),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(entry.type.icon, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.rawValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.type.label} · ${_formatDate(entry.scannedAt)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
