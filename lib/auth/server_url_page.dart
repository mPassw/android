import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/auth/login_page.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/secure_storage.dart';

class ServerUrlPage extends StatefulWidget {
  const ServerUrlPage({super.key});

  @override
  State<ServerUrlPage> createState() => _ServerUrlPageState();
}

class _ServerUrlPageState extends State<ServerUrlPage> {
  final secureStorage = SecureStorage.instance;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLastServerUrl();
  }

  Future<void> _getLastServerUrl() async {
    try {
      _textEditingController.text = await secureStorage.getServerUrl();
    } catch (e) {
      log("No saved server URL found");
    }
  }

  Future<void> validateServer(BuildContext context) async {
    try {
      LoadingDialog.show(context);
      await AuthorizationService.validateServer(_textEditingController.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Valid Server URL"));
      LoadingDialog.hide(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return const Login();
      }));
    } catch (e) {
      log(e.toString());
      LoadingDialog.hide(context);
      if (e is CustomException) {
        ScaffoldMessenger.of(context).showSnackBar(Sonner(message: e.message));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Unknown error"));
      }
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Align(
                  // Use Align for positioning
                  alignment:
                      const Alignment(0.0, -0.5), // Adjust vertical position
                  child: SingleChildScrollView(
                    // For scrollability
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Server Validation",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Enter the URL of your mPass instance",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.withAlpha(200)),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextField(
                            controller:
                                _textEditingController, // Define _textEditingController
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "URL",
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  validateServer(context);
                                },
                                child: const Text("Next",
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
