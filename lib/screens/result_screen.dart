/// Tela que exibe o conteúdo interpretado de um QR Code e ações
/// contextuais (abrir link, ligar, copiar, compartilhar, etc.).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/qr_type_presentation.dart';
import '../core/snackbar_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/parsed_qr_content.dart';
import '../models/qr_content_type.dart';
import '../services/safe_action_uri.dart';
import '../widgets/labeled_value.dart';
import '../widgets/neon_action_button.dart';
import '../widgets/neon_container.dart';

/// Mostra o resultado de uma leitura de QR Code já classificada.
///
/// Esta tela é "burra" em relação à origem do dado: tanto faz se o
/// [content] veio de uma leitura recém-feita pela câmera ou de um item
/// reaberto no histórico — a exibição e as ações são as mesmas.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.content});

  final ParsedQrContent content;

  /// Cria a rota única usada para abrir um resultado recém-lido ou salvo.
  static MaterialPageRoute<void> route(ParsedQrContent content) {
    return MaterialPageRoute(builder: (_) => ResultScreen(content: content));
  }

  @override
  Widget build(BuildContext context) {
    final type = content.type;

    return Scaffold(
      appBar: AppBar(title: const Text('RESULTADO')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeBadge(type: type),
              const SizedBox(height: 20),
              NeonContainer(
                color: type.accentColor,
                child: _buildContentDetails(context),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _buildActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Monta o corpo do painel de detalhes de acordo com o tipo de
  /// conteúdo. Tipos com campos estruturados (Wi-Fi, contato, etc.) têm
  /// uma exibição dedicada; os demais mostram o texto bruto.
  Widget _buildContentDetails(BuildContext context) {
    switch (content.type) {
      case QrContentType.wifi:
        return _WifiDetails(content: content);
      case QrContentType.contact:
        return _KeyValueDetails(
          fields: {
            'Nome': content.fields['name'],
            'Telefone': content.fields['phone'],
            'E-mail': content.fields['email'],
          },
        );
      case QrContentType.email:
        return _KeyValueDetails(
          fields: {
            'Endereço': content.fields['address'],
            'Assunto': content.fields['subject'],
            'Mensagem': content.fields['body'],
          },
        );
      case QrContentType.sms:
        return _KeyValueDetails(
          fields: {
            'Número': content.fields['number'],
            'Mensagem': content.fields['body'],
          },
        );
      case QrContentType.geo:
        return _KeyValueDetails(
          fields: {
            'Latitude': content.fields['latitude'],
            'Longitude': content.fields['longitude'],
          },
        );
      case QrContentType.phone:
      case QrContentType.url:
      case QrContentType.plainText:
        return SelectableText(
          content.rawValue,
          style: AppTextStyles.mono(fontSize: 15).copyWith(height: 1.5),
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[
      NeonActionButton(
        icon: Icons.copy_rounded,
        label: 'Copiar',
        onPressed: () => _copyToClipboard(context, content.rawValue),
      ),
      NeonActionButton(
        icon: Icons.share_rounded,
        label: 'Compartilhar',
        onPressed: () => SharePlus.instance.share(
          ShareParams(text: content.rawValue),
        ),
      ),
    ];

    switch (content.type) {
      case QrContentType.url:
        actions.insert(
          0,
          NeonActionButton(
            icon: Icons.open_in_new_rounded,
            label: 'Abrir',
            onPressed: () => _openLink(context),
          ),
        );
      case QrContentType.phone:
        actions.insert(
          0,
          NeonActionButton(
            icon: Icons.call_rounded,
            label: 'Ligar',
            onPressed: () => _launch(
              context,
              SafeActionUri.phone(
                content.fields['number'] ?? content.rawValue,
              ),
            ),
          ),
        );
      case QrContentType.sms:
        actions.insert(
          0,
          NeonActionButton(
            icon: Icons.sms_rounded,
            label: 'Enviar SMS',
            onPressed: () => _launch(
              context,
              SafeActionUri.sms(
                content.fields['number'] ?? '',
                content.fields['body'] ?? '',
              ),
            ),
          ),
        );
      case QrContentType.email:
        actions.insert(
          0,
          NeonActionButton(
            icon: Icons.email_rounded,
            label: 'E-mail',
            onPressed: () => _launch(
              context,
              SafeActionUri.email(
                content.fields['address'] ?? '',
                subject: content.fields['subject'] ?? '',
                body: content.fields['body'] ?? '',
              ),
            ),
          ),
        );
      case QrContentType.geo:
        final lat = content.fields['latitude'] ?? '';
        final lng = content.fields['longitude'] ?? '';
        actions.insert(
          0,
          NeonActionButton(
            icon: Icons.map_rounded,
            label: 'Abrir mapa',
            onPressed: () => _launch(context, SafeActionUri.map(lat, lng)),
          ),
        );
      case QrContentType.wifi:
        final password = content.fields['password'] ?? '';
        if (password.isNotEmpty) {
          actions.insert(
            0,
            NeonActionButton(
              icon: Icons.password_rounded,
              label: 'Copiar senha',
              onPressed: () => _copyToClipboard(context, password),
            ),
          );
        }
      case QrContentType.contact:
      case QrContentType.plainText:
        break;
    }

    return actions;
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    context.showFeedbackSnackBar('Copiado para a área de transferência');
  }

  /// Abre um link lido do QR Code, mas só depois de mostrar o endereço
  /// completo e ter a confirmação do usuário.
  ///
  /// QR Codes são o vetor clássico de phishing justamente porque o
  /// destino é invisível antes de abrir: o adesivo diz "pague aqui" e o
  /// link vai para outro lugar. Confirmar com o host em destaque é o que
  /// dá ao usuário a chance de perceber isso.
  Future<void> _openLink(BuildContext context) async {
    final uri = SafeActionUri.web(content.rawValue);
    if (uri == null) {
      context.showFeedbackSnackBar('Não foi possível abrir este conteúdo');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir link externo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uri.host,
              style: AppTextStyles.mono().copyWith(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              uri.toString(),
              style: AppTextStyles.mono(fontSize: 13).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _launch(context, uri);
  }

  Future<void> _launch(BuildContext context, Uri? uri) async {
    if (uri == null ||
        !SafeActionUri.isAllowed(uri) ||
        !await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      context.showFeedbackSnackBar('Não foi possível abrir este conteúdo');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Selo no topo da tela indicando o tipo de conteúdo detectado
/// (ex.: "Link", "Rede Wi-Fi").
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final QrContentType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(type.icon, color: type.accentColor),
        const SizedBox(width: 8),
        Text(
          type.label.toUpperCase(),
          style: TextStyle(
            color: type.accentColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Exibe uma lista de campos rotulados (usado por e-mail, SMS, geo,
/// contato). Campos nulos ou vazios são omitidos.
class _KeyValueDetails extends StatelessWidget {
  const _KeyValueDetails({required this.fields});

  final Map<String, String?> fields;

  @override
  Widget build(BuildContext context) {
    final entries = fields.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return const Text(
        'Nenhuma informação adicional disponível.',
        style: AppTextStyles.secondaryMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries) ...[
          LabeledValue(label: entry.key, value: entry.value!),
          if (entry != entries.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Exibição dedicada para redes Wi-Fi: mostra SSID, segurança e senha
/// (oculta por padrão, com opção de revelar).
class _WifiDetails extends StatefulWidget {
  const _WifiDetails({required this.content});

  final ParsedQrContent content;

  @override
  State<_WifiDetails> createState() => _WifiDetailsState();
}

class _WifiDetailsState extends State<_WifiDetails> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final ssid = widget.content.fields['ssid'] ?? '';
    final password = widget.content.fields['password'] ?? '';
    final security = widget.content.fields['security'] ?? 'nopass';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledValue(
          label: 'Nome da rede (SSID)',
          value: ssid.isEmpty ? '(oculto)' : ssid,
          fontSize: 16,
        ),
        const SizedBox(height: 14),
        LabeledValue(
          label: 'Segurança',
          value: security,
          fontSize: 14,
          selectable: false,
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 14),
          LabeledValue(
            label: 'Senha',
            value: _passwordVisible ? password : '•' * password.length,
            fontSize: 16,
            selectable: false,
            trailing: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
            ),
          ),
        ],
      ],
    );
  }
}
