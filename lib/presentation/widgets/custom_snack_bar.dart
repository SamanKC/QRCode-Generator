import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show(BuildContext context, String message, {color}) {
    final snackbar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: color ?? Colors.black87,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      showCloseIcon: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
