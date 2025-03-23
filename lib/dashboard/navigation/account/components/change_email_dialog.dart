import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/account/model/update_username_params.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class ChangeEmailDialogContent extends StatefulWidget {
  const ChangeEmailDialogContent({super.key});

  @override
  State<ChangeEmailDialogContent> createState() =>
      _ChangeEmailDialogContentState();
}

class _ChangeEmailDialogContentState extends State<ChangeEmailDialogContent> {
  bool _obscureText = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _saveSettings(BuildContext context) async {
    try {
      PasswordsState passwordsState =
          Provider.of<PasswordsState>(context, listen: false);
      UserState userState = Provider.of<UserState>(context, listen: false);

      final email = _emailController.text;
      final masterPassword = _passwordController.text;
      if (!CustomUtils.isValidEmail(email)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Invalid email"));
        return;
      }
      LoadingDialog.show(context);
      final validated =
          await AuthorizationService.validatePassword(masterPassword);
      if (!validated) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Invalid master password"));
        return;
      }

      await userState.checkEmailAvailability(email);

      final code = _codeController.text;

      final Map<String, String> verifierAndSalt =
          await AuthorizationService.generateVerifierAndSalt(
              email, masterPassword);

      final String? hexVerifier = verifierAndSalt["verifier"];
      final String? hexSalt = verifierAndSalt["salt"];

      final String hexEncryptionKey =
          await AuthorizationService.calculateEncryptionKey(
              masterPassword, hexSalt ?? "");

      final String hexDecryptionKey = await passwordsState.getEncryptionKey();

      List<Password> encryptedPasswords = await userState.reEncryptPasswords(
          passwordsState.passwordList, hexEncryptionKey, hexDecryptionKey);

      await userState.changeUser(UpdateUsernameParams(
          email: email,
          salt: hexSalt,
          verifier: hexVerifier,
          code: code,
          passwords: encryptedPasswords));

      if (!context.mounted) return;
      LoadingDialog.hide(context);
      await AuthorizationService.logout(context, "Email Changed");
    } catch (error) {
      log(error.toString());
      if (!context.mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to change email"));
      }
    } finally {
      if (context.mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UserState userState = Provider.of<UserState>(context, listen: false);
    final email = userState.user.email;

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Change Email',
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      labelText: "New Email",
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
                      "Note: Changing the email will also re-encrypt all passwords."
                      "This will log you out of all devices.",
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
