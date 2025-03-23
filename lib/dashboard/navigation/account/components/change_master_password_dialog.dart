import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/account/model/update_username_params.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class ChangeMasterPasswordDialogContent extends StatefulWidget {
  const ChangeMasterPasswordDialogContent({super.key});

  @override
  State<ChangeMasterPasswordDialogContent> createState() =>
      _ChangeMasterPasswordDialogContentState();
}

class _ChangeMasterPasswordDialogContentState
    extends State<ChangeMasterPasswordDialogContent> {
  bool _obscureText = true;
  bool _obscureText2 = true;
  bool _obscureText3 = true;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _saveSettings(BuildContext context) async {
    try {
      UserState userState = Provider.of<UserState>(context, listen: false);
      PasswordsState passwordsState =
          Provider.of<PasswordsState>(context, listen: false);

      final email = userState.user.email ?? "";
      final masterPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final code = _codeController.text;

      if (masterPassword.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Master password cannot be empty"));
        return;
      }
      if (newPassword.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "New password cannot be empty"));
        return;
      }
      if (confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Confirm password cannot be empty"));
        return;
      }
      if (code.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Code cannot be empty"));
        return;
      }
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "New passwords do not match"));
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

      final Map<String, String> verifierAndSalt =
          await AuthorizationService.generateVerifierAndSalt(
              email, newPassword);

      final String? hexVerifier = verifierAndSalt["verifier"];
      final String? hexSalt = verifierAndSalt["salt"];

      final String hexEncryptionKey =
          await AuthorizationService.calculateEncryptionKey(
              newPassword, hexSalt ?? "");

      final String hexDecryptionKey = await passwordsState.getEncryptionKey();

      List<Password> encryptedPasswords = await userState.reEncryptPasswords(
          passwordsState.passwordList, hexEncryptionKey, hexDecryptionKey);

      await userState.changeUser(UpdateUsernameParams(
          code: code,
          salt: hexSalt,
          verifier: hexVerifier,
          passwords: encryptedPasswords));

      if (!context.mounted) return;
      LoadingDialog.hide(context);
      await AuthorizationService.logout(context, "Master Password Changed");
    } catch (error) {
      log(error.toString());
      if (!context.mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to change master password"));
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
    final email = userState.user.email ?? "";

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Change Master Password',
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
                    controller: _currentPasswordController,
                    obscureText: _obscureText,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Current Password",
                      prefixIcon: const Icon(Icons.key),
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
                    controller: _newPasswordController,
                    obscureText: _obscureText2,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "New Password",
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText2
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText2 = !_obscureText2;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureText3,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Confirm New Password",
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText3
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText3 = !_obscureText3;
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
                      "Note: Changing the master password will also re-encrypt all passwords."
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
