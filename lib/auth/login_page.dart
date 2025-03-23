import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:mpass/auth/register_page.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/dashboard.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/secure_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscureText = true;

  final secureStorage = SecureStorage.instance;
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLastEmail();
  }

  Future<void> _getLastEmail() async {
    try {
      _loginController.text = await secureStorage.getEmail();
    } catch (e) {
      dev.log("No saved email found");
    }
  }

  Future<void> login(BuildContext context) async {
    final String email = _loginController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      LoadingDialog.show(context);
      if (email.isEmpty) throw CustomException("Email is required");
      if (password.isEmpty) throw CustomException("Password is required");

      await AuthorizationService.login(email, password);
      if (!context.mounted) return;
      LoadingDialog.hide(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      dev.log(e.toString());
      if (e is CustomException) {
        ScaffoldMessenger.of(context).showSnackBar(Sonner(message: e.message));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Unknown error"));
      }
      LoadingDialog.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Row(
              // Back Button
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ],
            ),
            Flexible(
              flex: 2, // Adjust flex as needed
              child: Align(
                alignment: const Alignment(0.0, -0.5), // Adjust these values
                child: SingleChildScrollView(
                  // For scrollability
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Signin",
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        spacing: 8,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextField(
                              controller:
                                  _loginController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.account_circle_outlined),
                                border: OutlineInputBorder(),
                                labelText: "Email/Username",
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextField(
                              controller:
                                  _passwordController, 
                              obscureText:
                                  _obscureText, 
                              keyboardType: TextInputType.visiblePassword,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "Password",
                                prefixIcon: Icon(Icons.password),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) {
                            return const Register(); // Assuming Register is defined
                          }));
                        },
                        child:
                            const Text("Don't have an account? Sign up here"),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await login(context); // Assuming login() is defined
                              },
                              child: const Text("Sign in",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
