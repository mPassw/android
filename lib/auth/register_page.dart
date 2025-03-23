import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/secure_storage.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscureText = true;
  bool _obscureText2 = true;

  final secureStorage = SecureStorage.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> register(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    try {
      if (email.isEmpty) {
        throw CustomException("Email is required");
      }
      if (password.isEmpty) {
        throw CustomException("Password is required");
      }
      if (confirmPassword.isEmpty) {
        throw CustomException("Confirm Password is required");
      }
      if (password != confirmPassword) {
        throw CustomException("Passwords do not match");
      }

      LoadingDialog.show(context);
      await AuthorizationService.register(email, password, username);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Account created!"));
      LoadingDialog.hide(context);
      Navigator.pop(context);
    } catch (e) {
      dev.log(e.toString());
      if (e is CustomException) {
        ScaffoldMessenger.of(context).showSnackBar(Sonner(message: e.message));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          Sonner(message: "An unexpected error occurred"),
        );
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
          child: Column(
            children: [
              Expanded(
                // Use Expanded to fill available space
                child: Align(
                  // Use Align for positioning
                  alignment:
                      const Alignment(0.0, -0.5), // Adjust vertical position
                  child: SingleChildScrollView(
                    // For scrollability
                    child: Column(
                      spacing: 2,
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center content vertically
                      mainAxisSize:
                          MainAxisSize.min, // Prevent unnecessary expansion
                      children: [
                        Text(
                          "Signup",
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
                                    _emailController, // Define _emailController
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                  labelText: "Email",
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller:
                                    _usernameController, // Define _usernameController
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.account_circle_outlined),
                                  border: OutlineInputBorder(),
                                  labelText: "Username",
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller:
                                    _passwordController, // Define _passwordController
                                obscureText:
                                    _obscureText, // Define _obscureText
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
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller:
                                    _confirmPasswordController, // Define _confirmPasswordController
                                obscureText:
                                    _obscureText2, // Define _obscureText2
                                keyboardType: TextInputType.visiblePassword,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: "Repeat Password",
                                  prefixIcon: Icon(Icons.password),
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                              "Already have an account? Sign in here"),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          // Make the button full width
                          width: double.infinity, // Key change: full width
                          child: FilledButton(
                            onPressed: () async {
                              await register(context); // Define register()
                            },
                            child: const Text("sign up",
                                style: TextStyle(fontSize: 16)),
                          ),
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
