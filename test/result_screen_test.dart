// Tela de resultado: exibição por tipo de conteúdo e ações contextuais.
//
// Os plugins nativos usados aqui (url_launcher, share_plus e a área de
// transferência) são substituídos por handlers de canal falsos, para que os
// testes rodem na máquina de desenvolvimento e possam verificar exatamente
// qual URI cada ação tentaria abrir.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_reader/models/parsed_qr_content.dart';
import 'package:qr_code_reader/models/qr_content_type.dart';
import 'package:qr_code_reader/screens/result_screen.dart';
import 'package:qr_code_reader/widgets/neon_action_button.dart';

void main() {
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  late List<MethodCall> launcherCalls;
  late List<MethodCall> shareCalls;
  late List<MethodCall> clipboardCalls;
  var canLaunch = true;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    launcherCalls = [];
    shareCalls = [];
    clipboardCalls = [];
    canLaunch = true;

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(urlLauncherChannel, (call) async {
      launcherCalls.add(call);
      return switch (call.method) {
        'canLaunch' => canLaunch,
        'launch' => true,
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return 'dev.fluttercommunity.plus/share/success';
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(urlLauncherChannel, null);
    messenger.setMockMethodCallHandler(shareChannel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpResult(WidgetTester tester, ParsedQrContent content) async {
    await tester.pumpWidget(MaterialApp(home: ResultScreen(content: content)));
    await tester.pumpAndSettle();
  }

  /// URIs que o botão [label] pediu para abrir.
  List<String> launchedUris() => launcherCalls
      .where((c) => c.method == 'launch')
      .map((c) => (c.arguments as Map)['url'] as String)
      .toList();

  group('ResultScreen — exibição por tipo', () {
    testWidgets('link mostra o texto bruto e o selo "LINK"', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'https://flutter.dev',
          type: QrContentType.url,
        ),
      );

      expect(find.text('LINK'), findsOneWidget);
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('texto simples não oferece ações além de copiar/compartilhar',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'apenas texto',
          type: QrContentType.plainText,
        ),
      );

      expect(find.byType(NeonActionButton), findsNWidgets(2));
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
    });

    testWidgets('e-mail lista endereço, assunto e mensagem', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'mailto:contato@exemplo.com',
          type: QrContentType.email,
          fields: {
            'address': 'contato@exemplo.com',
            'subject': 'Assunto',
            'body': 'Mensagem',
          },
        ),
      );

      expect(find.text('ENDEREÇO'), findsOneWidget);
      expect(find.text('contato@exemplo.com'), findsOneWidget);
      expect(find.text('ASSUNTO'), findsOneWidget);
      expect(find.text('Mensagem'), findsOneWidget);
    });

    testWidgets('campos vazios são omitidos da lista de detalhes',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'sms:+5511999998888',
          type: QrContentType.sms,
          fields: {'number': '+5511999998888', 'body': ''},
        ),
      );

      expect(find.text('NÚMERO'), findsOneWidget);
      expect(find.text('MENSAGEM'), findsNothing);
    });

    testWidgets('sem nenhum campo preenchido mostra aviso de ausência',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'BEGIN:VCARD\nEND:VCARD',
          type: QrContentType.contact,
        ),
      );

      expect(
        find.text('Nenhuma informação adicional disponível.'),
        findsOneWidget,
      );
    });

    testWidgets('geo mostra latitude e longitude', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'geo:-23.55,-46.63',
          type: QrContentType.geo,
          fields: {'latitude': '-23.55', 'longitude': '-46.63'},
        ),
      );

      expect(find.text('LATITUDE'), findsOneWidget);
      expect(find.text('-46.63'), findsOneWidget);
    });
  });

  group('ResultScreen — Wi-Fi', () {
    const wifi = ParsedQrContent(
      rawValue: 'WIFI:T:WPA;S:MinhaRede;P:segredo;;',
      type: QrContentType.wifi,
      fields: {
        'ssid': 'MinhaRede',
        'password': 'segredo',
        'security': 'WPA',
        'hidden': 'false',
      },
    );

    testWidgets('esconde a senha até o usuário pedir para revelar',
        (tester) async {
      await pumpResult(tester, wifi);

      expect(find.text('MinhaRede'), findsOneWidget);
      expect(find.text('WPA'), findsOneWidget);
      expect(find.text('•' * 'segredo'.length), findsOneWidget);
      expect(find.text('segredo'), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();

      expect(find.text('segredo'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('copiar senha usa a senha, não o texto bruto', (tester) async {
      await pumpResult(tester, wifi);

      await tester.tap(find.text('Copiar senha'));
      await tester.pump();

      expect(clipboardCalls.single.arguments['text'], 'segredo');
    });

    testWidgets('sem senha não oferece "Copiar senha" nem o campo SENHA',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'WIFI:T:nopass;S:Aberta;;',
          type: QrContentType.wifi,
          fields: {'ssid': 'Aberta', 'password': '', 'security': 'nopass'},
        ),
      );

      expect(find.text('Copiar senha'), findsNothing);
      expect(find.text('SENHA'), findsNothing);
    });

    testWidgets('SSID vazio é exibido como "(oculto)"', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'WIFI:T:WPA;P:segredo;;',
          type: QrContentType.wifi,
          fields: {'ssid': '', 'password': 'segredo', 'security': 'WPA'},
        ),
      );

      expect(find.text('(oculto)'), findsOneWidget);
    });
  });

  group('ResultScreen — ações', () {
    testWidgets('copiar coloca o texto bruto na área de transferência',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'conteúdo lido',
          type: QrContentType.plainText,
        ),
      );

      await tester.tap(find.text('Copiar'));
      await tester.pump();

      expect(clipboardCalls.single.arguments['text'], 'conteúdo lido');
      expect(
        find.text('Copiado para a área de transferência'),
        findsOneWidget,
      );
    });

    testWidgets('compartilhar envia o texto bruto ao menu do sistema',
        (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'conteúdo lido',
          type: QrContentType.plainText,
        ),
      );

      await tester.tap(find.text('Compartilhar'));
      await tester.pump();

      expect(shareCalls, isNotEmpty);
    });

    testWidgets('abrir link dispara o launcher com a URL lida', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'https://flutter.dev',
          type: QrContentType.url,
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(launchedUris(), ['https://flutter.dev']);
    });

    testWidgets('ligar monta um URI tel:', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'tel:+5511999998888',
          type: QrContentType.phone,
          fields: {'number': '+5511999998888'},
        ),
      );

      await tester.tap(find.text('Ligar'));
      await tester.pumpAndSettle();

      expect(launchedUris(), ['tel:+5511999998888']);
    });

    testWidgets('enviar SMS codifica a mensagem no corpo', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'SMSTO:+551199999999:Ola mundo',
          type: QrContentType.sms,
          fields: {'number': '+551199999999', 'body': 'Ola mundo'},
        ),
      );

      await tester.tap(find.text('Enviar SMS'));
      await tester.pumpAndSettle();

      expect(launchedUris(), ['sms:+551199999999?body=Ola%20mundo']);
    });

    testWidgets('e-mail monta mailto: com assunto e corpo', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'mailto:contato@exemplo.com',
          type: QrContentType.email,
          fields: {
            'address': 'contato@exemplo.com',
            'subject': 'Oi',
            'body': 'Tudo bem?',
          },
        ),
      );

      await tester.tap(find.text('E-mail'));
      await tester.pumpAndSettle();

      expect(
        launchedUris(),
        ['mailto:contato@exemplo.com?subject=Oi&body=Tudo%20bem%3F'],
      );
    });

    testWidgets('abrir mapa usa as coordenadas lidas', (tester) async {
      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'geo:-23.55,-46.63',
          type: QrContentType.geo,
          fields: {'latitude': '-23.55', 'longitude': '-46.63'},
        ),
      );

      await tester.tap(find.text('Abrir mapa'));
      await tester.pumpAndSettle();

      expect(launchedUris().single, contains('mlat=-23.55&mlon=-46.63'));
    });

    testWidgets('avisa quando nenhum app consegue abrir o conteúdo',
        (tester) async {
      canLaunch = false;

      await pumpResult(
        tester,
        const ParsedQrContent(
          rawValue: 'https://flutter.dev',
          type: QrContentType.url,
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(launchedUris(), isEmpty);
      expect(
        find.text('Não foi possível abrir este conteúdo'),
        findsOneWidget,
      );
    });
  });
}
