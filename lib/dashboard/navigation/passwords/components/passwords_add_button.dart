import 'package:flutter/material.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/passwords/components/password_dialog.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:provider/provider.dart';

class PasswordsAddButton extends StatefulWidget {
  const PasswordsAddButton({super.key});

  @override
  State<PasswordsAddButton> createState() => _PasswordsAddButtonState();
}

class _PasswordsAddButtonState extends State<PasswordsAddButton> {
  @override
  Widget build(BuildContext context) {
    UserState userState = Provider.of<UserState>(context, listen: false);
    final isVerified = userState.user.verified;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          TextButton.icon(
              onPressed: isVerified == false ? null : () {
                showPasswordEditDialog(context, Password(decrypted: true), "Add Password");
              },
              label: const Text('Add Password'),
              icon: const Icon(Icons.add))
        ]));
  }
}
