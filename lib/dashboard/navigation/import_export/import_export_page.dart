import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/import_export/state/export_service.dart';
import 'package:mpass/dashboard/navigation/import_export/state/export_state.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool _obscureText = true;

  final TextEditingController _passwordController = TextEditingController();

  Future<void> _exportPasswords() async {
    try {
      LoadingDialog.show(context);

      PasswordsState passwordsState =
          Provider.of<PasswordsState>(context, listen: false);
      ExportState exportState =
          Provider.of<ExportState>(context, listen: false);

      final selectedValue = exportState.selectedValue;
      final masterPassword = _passwordController.text;
      final isPasswordValid =
          await AuthorizationService.validatePassword(masterPassword);

      if (!isPasswordValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Invalid master password"));
        return;
      }
      List<Password> passwordList = passwordsState.passwordList;

      List<Password> decryptedPasswords =
          await ExportService.decryptAllPasswords(passwordList);

      bool isSuccess = false;
      switch (selectedValue) {
        case 'JSON':
          isSuccess = await ExportService.exportToJson(decryptedPasswords);
          break;
        case 'CSV':
          isSuccess = await ExportService.exportToCsv(decryptedPasswords);
          break;
      }

      if (!isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to export passwords"));
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Passwords exported"));
    } catch (error) {
      log(error.toString());
      if (!mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to export passwords"));
      }
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ExportState exportState = Provider.of<ExportState>(context, listen: false);
    String selectedValue = exportState.selectedValue;
    List<String> options = exportState.options;

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Export",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedValue,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "File Type",
                            prefixIcon: const Icon(Icons.extension_outlined),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                exportState.setSelectedValue(newValue);
                              });
                            }
                          },
                          items: options.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
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
                              "Note: export may take a while depending on the number of passwords you have.",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: _exportPasswords,
                              child: Text("Export")),
                        )
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
