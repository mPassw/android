import 'package:flutter/material.dart';

class DialogUtils {
  static Future<bool?> showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
