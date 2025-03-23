import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

Future<void> showSendTestEmailDialog(BuildContext context) {
  final adminState = Provider.of<AdminState>(context, listen: false);
  final TextEditingController emailController = TextEditingController();
  final ThemeData theme = Theme.of(context);

  Future<void> sendEmail() async {
    try {
      LoadingDialog.show(context);
      await adminState.sendTestEmail(emailController.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Message Sent"));
      Navigator.of(context).pop();
    } catch (error) {
      log(error.toString());
      if (error is Exception) HttpService.parseException(context, error);
    } finally {
      LoadingDialog.hide(context);
    }
  }

  return showGeneralDialog<String>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.center,
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: EdgeInsets.all(16.0),
            width: 300,
            color: theme.colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Send Test Email",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                    controller: emailController,
                    decoration: InputDecoration(hintText: "Recipient Email")),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel"),
                    ),
                    SizedBox(width: 8),
                    FilledButton(
                      onPressed: sendEmail,
                      child: Text("Send"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
    transitionDuration: Duration(milliseconds: 200),
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    barrierColor: Colors.black.withValues(alpha: 0.5),
  );
}
