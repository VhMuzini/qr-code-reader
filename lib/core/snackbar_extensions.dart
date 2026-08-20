/// Feedback visual breve exibido na parte inferior das telas.
library;

import 'package:flutter/material.dart';

/// Centraliza a criação de avisos para que ações semelhantes tenham
/// comportamento e apresentação consistentes.
extension SnackBarFeedback on BuildContext {
  /// Exibe [message] usando o tema de snackbar do aplicativo.
  void showFeedbackSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
