/// Mapeamento entre [QrContentType] e sua apresentação visual (ícone/cor).
library;

import 'package:flutter/material.dart';

import '../models/qr_content_type.dart';
import 'theme/app_colors.dart';

/// Reúne, em um único lugar, o ícone e a cor de destaque usados para
/// representar cada [QrContentType]. Usado tanto na tela de resultado
/// quanto na lista de histórico, para manter os dois visualmente
/// consistentes.
extension QrContentTypePresentation on QrContentType {
  IconData get icon => switch (this) {
        QrContentType.url => Icons.link_rounded,
        QrContentType.wifi => Icons.wifi_rounded,
        QrContentType.email => Icons.email_rounded,
        QrContentType.phone => Icons.phone_rounded,
        QrContentType.sms => Icons.sms_rounded,
        QrContentType.geo => Icons.place_rounded,
        QrContentType.contact => Icons.contact_page_rounded,
        QrContentType.plainText => Icons.notes_rounded,
      };

  Color get accentColor => switch (this) {
        QrContentType.url => AppColors.neonCyan,
        QrContentType.wifi => AppColors.neonGreen,
        QrContentType.email => AppColors.neonMagenta,
        QrContentType.phone => AppColors.neonGreen,
        QrContentType.sms => AppColors.neonMagenta,
        QrContentType.geo => AppColors.neonPurple,
        QrContentType.contact => AppColors.neonPurple,
        QrContentType.plainText => AppColors.neonCyan,
      };
}
