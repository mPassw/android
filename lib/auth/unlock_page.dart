import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/components/warning_card.dart';
import 'package:mpass/dashboard/dashboard.dart';
import 'package:mpass/dashboard/navigation/passwords/components/password_dialog.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/passwords_page.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/network_state.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:provider/provider.dart';

class UnlockPage extends StatefulWidget {
  const UnlockPage(
      {super.key,
      this.flutterEngineId,
      this.isAutofill = false,
      this.isAutosave = false});

  final String? flutterEngineId;
  final bool isAutofill;
  final bool isAutosave;

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  String _email = "";
  bool _obscureText = true;

  String? _passwordId;
  String? _username;
  String? _password;
  String? _packageName;

  final secureStorage = SecureStorage.instance;
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();

  MethodChannel _channel = const MethodChannel("");

  @override
  void initState() {
    super.initState();
    _loadEmail();
    if (widget.isAutofill) {
      _channel = MethodChannel(widget.flutterEngineId ?? "");
      final autofillState = Provider.of<AutofillState>(context, listen: false);
      autofillState.setIsAutofill(widget.isAutofill);
      autofillState.setIsAutosave(widget.isAutosave);
      autofillState.setFlutterEngineId(widget.flutterEngineId ?? "");
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
    _channel.setMethodCallHandler((call) async {
      if (call.method == "initializeAutofill") {
        final passwordId = call.arguments['passwordId'] as String?;
        _passwordId = passwordId;
        _authenticateWithBiometrics();
        return true;
      }
      if (call.method == "initializeAutosave") {
        final username = call.arguments['username'] as String?;
        final password = call.arguments['password'] as String?;
        final packageName = call.arguments['packageName'] as String?;

        _username = username;
        _password = password;
        _packageName = packageName;
        _authenticateWithBiometrics();
        return true;
      }
      return null;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final isAutofillState =
          Provider.of<AutofillState>(context, listen: false);
      bool isAutofill = isAutofillState.isAutofill;
      bool isAutosave = isAutofillState.isAutosave;
      final canUseBiometrics = await _auth.canCheckBiometrics;
      if (!canUseBiometrics) {
        return;
      }

      final authenticated =
          await _auth.authenticate(localizedReason: "Authenticate to mPass");

      if (authenticated) {
        if (mounted) {
          LoadingDialog.show(context);
        }

        final password = await secureStorage.getMasterPassword();
        if (isAutosave) {
          await savePassword();
        } else if (isAutofill) {
          await getPassword();
        } else {
          await _login(password);
        }
      }
    } catch (e) {
      log(e.toString());
      _handleAuthError(e);
      if (!mounted) return;
      LoadingDialog.hide(context);
    }
  }

  Future<void> _authenticateWithPassword() async {
    try {
      LoadingDialog.show(context);
      final isAutofillState =
          Provider.of<AutofillState>(context, listen: false);
      bool isAutofill = isAutofillState.isAutofill;
      bool isAutosave = isAutofillState.isAutosave;
      final password = _passwordController.text.trim();
      if (isAutosave) {
        await savePassword();
      } else if (isAutofill) {
        final isValid = await AuthorizationService.validatePassword(password);
        if (!isValid) {
          throw CustomException("Invalid password");
        }
        await getPassword();
      } else {
        await _login(password);
      }
    } catch (e) {
      log(e.toString());
      _handleAuthError(e);
      if (!mounted) return;
      LoadingDialog.hide(context);
    }
  }

  Future<void> savePassword() async {
    var password = Password(
        username: _username ?? "",
        password: _password ?? "",
        websites: List.of([_packageName ?? ""]),
        decrypted: true);
    if (mounted) {
      LoadingDialog.hide(context);
      Navigator.of(context)
          .pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => PasswordDialogContent(
                      dialogTitle: "Add Password",
                      currentPassword: password,
                      isEditModeEnabled: true)),
              (route) => false)
          .then((result) => {
                if (result == true)
                  {_channel.invokeMethod("autosaveSuccess", null)}
                else
                  {_channel.invokeMethod("autosaveFailed", null)}
              });
    }
  }

  Future<void> getPassword() async {
    final secureStorage = SecureStorage.instance;
    final encryptionKey = await secureStorage.getDerivedKey();
    final id = _passwordId;
    if (id != null) {
      final list = await PasswordsService.loadLocalPasswordList();
      final password = list.firstWhere((element) => element.id == id);
      final decryptedPassword = await PasswordsService.decryptPassword(
        password,
        encryptionKey,
      );
      _channel.invokeMethod('authenticationSuccessful', {
        'username': decryptedPassword.username,
        'password': decryptedPassword.password,
      });
      if (!mounted) return;
      LoadingDialog.hide(context);
    } else {
      if (!mounted) return;
      LoadingDialog.hide(context);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PasswordsPage()),
          (route) => false);
    }
  }

  Future<void> _login(String password) async {
    final networkState = Provider.of<NetworkState>(context, listen: false);
    if (!networkState.isConnected) {
      final isValid = await AuthorizationService.validatePassword(password);
      if (!isValid) {
        throw CustomException("Invalid password");
      }
    } else {
      await AuthorizationService.login(_email, password);
    }
    if (!mounted) return;
    LoadingDialog.hide(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Dashboard()),
      (route) => false,
    );
  }

  Future<void> _loadEmail() async {
    try {
      final secureStorage = SecureStorage.instance;
      final savedEmail = await secureStorage.getEmail();
      setState(() {
        _email = savedEmail;
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _logout() async {
    try {
      await AuthorizationService.logout(context);
    } catch (e) {
      _handleAuthError(e);
      if (!mounted) return;
      LoadingDialog.hide(context);
    }
  }

  void _handleAuthError(dynamic e) {
    if (e is CustomException) {
      ScaffoldMessenger.of(context).showSnackBar(Sonner(message: e.message));
    }
    if (e is NotFoundException && e.message == "User not found" ||
        e is BadRequestException && e.message == "Invalid credentials") {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkState = Provider.of<NetworkState>(context);
    final isAutofillState = Provider.of<AutofillState>(context);
    bool isAutofill = isAutofillState.isAutofill;
    bool connection = networkState.isConnected;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!connection)
              WarningCard(label: "Offline Mode", icon: Icons.wifi_off),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 15.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isAutofill
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      children: [
                        if (!isAutofill || !connection)
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                          ),
                        if (isAutofill)
                          IconButton(
                            onPressed: () {
                              _channel.invokeMethod('authenticationFailed');
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Align(
                        alignment: const Alignment(0.0, -0.6),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open, size: 97),
                              const SizedBox(height: 8),
                              const Text("Unlock mPass",
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text("Enter the master password for",
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey)),
                              Text(_email,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: "Password",
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
                              TextButton(
                                onPressed: () => _authenticateWithBiometrics(),
                                child: const Text("Use fingerprint to unlock"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _authenticateWithPassword(),
                        child: const Text("Unlock"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
