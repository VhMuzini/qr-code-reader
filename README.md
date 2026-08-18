# QR Scan — Leitor de QR Code Cyberpunk

Aplicativo Flutter para ler QR Codes com a câmera do celular, com visual
inspirado em interfaces cyberpunk (fundo escuro, neon ciano/magenta,
mira animada com "laser").

Sem anúncios, sem analytics, sem contas — o app só faz o que promete: ler
o QR Code e te entregar o conteúdo, com as ações certas para cada tipo
(abrir link, ligar, mandar SMS/e-mail, ver senha de Wi-Fi, etc.). Tudo
funciona **100% offline**; o histórico de leituras fica salvo apenas no
próprio aparelho.

## Funcionalidades

- Leitura de QR Code em tempo real, com moldura de mira e "laser" animado.
- Reconhecimento automático do tipo de conteúdo:
  - Links (`http`/`https`/`www.`)
  - Redes Wi-Fi (`WIFI:...`) — com opção de revelar/copiar a senha
  - E-mail (`mailto:`, `MATMSG:` ou endereço solto)
  - Telefone (`tel:`)
  - SMS (`sms:` / `SMSTO:`)
  - Localização (`geo:`)
  - Contato / vCard (`BEGIN:VCARD`)
  - Texto simples (fallback)
- Ações contextuais por tipo: abrir link, ligar, enviar SMS/e-mail, abrir
  mapa, copiar, compartilhar.
- Alternar lanterna e trocar de câmera (frontal/traseira) durante a leitura.
- Histórico local de leituras (buscar, reabrir, apagar item ou limpar tudo).
- Tema visual cyberpunk consistente em todo o app.

## Arquitetura do código

```
lib/
  core/
    theme/            # Paleta de cores e ThemeData cyberpunk
    qr_type_presentation.dart  # Ícone/cor de cada tipo de conteúdo
  models/              # Classes de dados (imutáveis, sem lógica de UI)
  services/
    qr_content_parser.dart     # Interpreta o texto bruto do QR Code
    scan_history_service.dart  # Persistência local (SharedPreferences)
  screens/
    scanner_screen.dart # Câmera + detecção
    result_screen.dart  # Conteúdo interpretado + ações
    history_screen.dart # Histórico local
  widgets/             # Componentes visuais reutilizáveis (overlay, botões)
  main.dart            # Ponto de entrada
test/
  qr_content_parser_test.dart  # Testes unitários do parser
  widget_test.dart              # Smoke test do app
```

O código é comentado com `///` (doc comments) explicando o *porquê* de
cada classe/decisão, não apenas o óbvio — a ideia é que o projeto sirva
também como material de estudo.

### Bibliotecas usadas

| Pacote | Para quê |
|---|---|
| [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) | Acesso à câmera e decodificação do QR Code (local, sem servidor) |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Guardar o histórico de leituras no dispositivo |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | Abrir links, discador, e-mail, SMS e mapas |
| [`share_plus`](https://pub.dev/packages/share_plus) | Menu nativo de compartilhamento |

Nenhuma dessas bibliotecas envia dados para servidores próprios do app —
`url_launcher` e `share_plus` só acionam apps/menus nativos do sistema
quando você toca em um botão de ação.

## Como rodar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install)
instalado (canal stable).

```bash
flutter create .   # regenera os ícones padrão de Android/iOS (ver nota abaixo)
flutter pub get
flutter run
```

> **Por que rodar `flutter create .`?** O ambiente onde este projeto foi
> criado não conseguiu enviar arquivos binários (os ícones `.png`
> padrão do Flutter) para o repositório Git. O comando acima é seguro:
> ele só recria arquivos ausentes (os ícones), sem sobrescrever
> `AndroidManifest.xml`, `Info.plist` ou qualquer código já
> personalizado — isso foi testado antes de escrever esta instrução.
> Depois disso, sinta-se à vontade para trocar os ícones padrão pelos
> seus próprios, em `android/app/src/main/res/mipmap-*` e
> `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

Para gerar um APK de release:

```bash
flutter build apk --release
```

### Permissões já configuradas

- **Android**: permissão de câmera em
  `android/app/src/main/AndroidManifest.xml` (o `minSdkVersion` do
  projeto, herdado do Flutter, já é 24 — acima do mínimo exigido pelo
  `mobile_scanner`).
- **iOS**: `NSCameraUsageDescription` em `ios/Runner/Info.plist`.
  Ao abrir o projeto no Xcode pela primeira vez (necessário um Mac),
  rode `pod install` dentro de `ios/` caso o Xcode peça.

## Testes e validação

Este projeto foi desenvolvido e validado em um ambiente Linux sem
Android SDK / Xcode instalados, então a build final de APK/IPA não pôde
ser executada aqui. O que **foi** validado neste ambiente:

```bash
flutter analyze   # 0 problemas
flutter test      # todos os testes passando
```

Recomenda-se rodar `flutter run` em um dispositivo/emulador real antes
de publicar, para conferir a câmera, a lanterna e a troca de câmera na
prática.

## Privacidade

- Nenhum dado é coletado, enviado ou compartilhado pelo app em segundo
  plano.
- O histórico de leituras fica salvo apenas localmente
  (`SharedPreferences`), e pode ser apagado a qualquer momento na tela
  de Histórico.
- Nenhuma biblioteca de anúncios ou analytics é usada.
