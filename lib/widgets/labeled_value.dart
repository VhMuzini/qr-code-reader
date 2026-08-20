/// Par visual reutilizável de rótulo e valor técnico.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

/// Exibe um rótulo em caixa alta, o espaçamento padrão e seu valor.
///
/// O slot [trailing] permite acrescentar uma ação sem alterar o alinhamento
/// dos valores, como no botão que revela a senha do Wi-Fi.
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.fontSize = 15,
    this.selectable = true,
    this.trailing,
  });

  final String label;
  final String value;
  final double fontSize;
  final bool selectable;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final valueWidget = selectable
        ? SelectableText(value, style: AppTextStyles.mono(fontSize: fontSize))
        : Text(value, style: AppTextStyles.mono(fontSize: fontSize));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.fieldLabel),
        const SizedBox(height: 2),
        if (trailing == null)
          valueWidget
        else
          Row(
            children: [
              Expanded(child: valueWidget),
              trailing!,
            ],
          ),
      ],
    );
  }
}
