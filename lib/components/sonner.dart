import 'package:flutter/material.dart';

class Sonner extends SnackBar {
  Sonner({
    super.key,
    required String message,
  }) : super(
          content: Text(message),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        );
}
