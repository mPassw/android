import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/account/model/update_username_params.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class ChangeUsernameDialogContent extends StatefulWidget {
  const ChangeUsernameDialogContent({super.key});

  @override
  State<ChangeUsernameDialogContent> createState() =>
      _ChangeUsernameDialogContentState();
}

class _ChangeUsernameDialogContentState
    extends State<ChangeUsernameDialogContent> {
  bool _obscureText = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _saveSettings(BuildContext context) async {
    try {
      final newUsername = _usernameController.text;
      final code = _codeController.text;
      if (newUsername.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
            Sonner(message: "Username must be at least 6 characters"));
        return;
      }
      if (code.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Code cannot be empty"));
        return;
      }

      LoadingDialog.show(context);
      final validated =
          await AuthorizationService.validatePassword(_passwordController.text);
      if (!validated) {
        if (!context.mounted) return;
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Invalid master password"));
        return;
      }
      if (!context.mounted) return;
      UserState userState = Provider.of<UserState>(context, listen: false);
      await userState
          .changeUser(UpdateUsernameParams(code: code, username: newUsername));

      if (!context.mounted) return;
      LoadingDialog.hide(context);
      await AuthorizationService.logout(context, "Username Changed");
    } catch (error) {
      log(error.toString());
      if (!context.mounted) return;
      LoadingDialog.hide(context);
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to change username"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UserState userState = Provider.of<UserState>(context, listen: false);
    final email = userState.user.email ?? "";

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Change Username',
            style: TextStyle(fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(),
                      labelText: "New Username",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(),
                      labelText: "Code",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("Request code to $email")),
                TextButton.icon(
                    onPressed: () async {
                      LoadingDialog.show(context);
                      await userState.sendCode(
                          context, userState.sendUpdateCode);
                      if (!context.mounted) return;
                      LoadingDialog.hide(context);
                    },
                    label: const Text("Send code"),
                    icon: const Icon(Icons.send_outlined)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Master Password",
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                      "Note: Changing the username will log you out of all devices.",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: () {
                        _saveSettings(context);
                      },
                      label: const Text("Change"),
                      icon: const Icon(Icons.save_outlined)),
                )
              ],
            ),
          ),
        ));
  }
}
