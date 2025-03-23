import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/generator/state/password_generator.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:provider/provider.dart';

class PasswordGeneratorTab extends StatefulWidget {
  const PasswordGeneratorTab({super.key});

  @override
  PasswordGeneratorTabState createState() => PasswordGeneratorTabState();
}

class PasswordGeneratorTabState extends State<PasswordGeneratorTab> {
  void generatePassword() {
    try {
      PasswordsGeneratorState passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      PasswordParams passwordParams = passwordsGeneratorState.passwordParams;
      String generatedValue =
          PasswordGenerator.generatePassword(passwordParams);
      passwordsGeneratorState.setGeneratedPassword(generatedValue);
    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Failed to generate"));
    }
  }

  @override
  Widget build(BuildContext context) {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context);
    PasswordParams passwordParams = passwordsGeneratorState.passwordParams;
    int maxNumbers =
        passwordParams.passwordLength - passwordParams.minimumSymbols - 2;
    int maxSymbols =
        passwordParams.passwordLength - passwordParams.minimumNumbers - 2;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Password Length"),
              Text("${passwordParams.passwordLength}"),
            ],
          ),
        ),
        Slider(
          value: passwordParams.passwordLength.toDouble(),
          onChanged: (value) {
            int maxNumbers = value.toInt() - passwordParams.minimumSymbols - 2;
            int maxSymbols = value.toInt() - passwordParams.minimumNumbers - 2;
            int minimumNumbers = passwordParams.minimumNumbers;
            int minimumSymbols = passwordParams.minimumSymbols;
            if (passwordParams.minimumNumbers > maxNumbers) {
              minimumNumbers = maxNumbers;
            }
            if (passwordParams.minimumSymbols > maxSymbols) {
              minimumSymbols = maxSymbols;
            }
            passwordsGeneratorState.setPasswordParams(passwordParams.copy(
                passwordLength: value.toInt(),
                minimumNumbers: minimumNumbers,
                minimumSymbols: minimumSymbols));
          },
          min: 4,
          max: 64,
          divisions: 64,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Minimum Numbers"),
              Text("${passwordParams.minimumNumbers}"),
            ],
          ),
        ),
        Slider(
          value: passwordParams.minimumNumbers.toDouble(),
          onChanged: (value) {
            passwordsGeneratorState.setPasswordParams(
                passwordParams.copy(minimumNumbers: value.toInt()));
          },
          min: 0,
          max: maxNumbers > 12 ? 12 : maxNumbers.toDouble(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Minimum Symbols"),
              Text("${passwordParams.minimumSymbols}"),
            ],
          ),
        ),
        Slider(
          value: passwordParams.minimumSymbols.toDouble(),
          onChanged: (value) {
            passwordsGeneratorState.setPasswordParams(
                passwordParams.copy(minimumSymbols: value.toInt()));
          },
          min: 0,
          max: maxSymbols > 12 ? 12 : maxSymbols.toDouble(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: FilledButton(
              onPressed: generatePassword, child: Text('Generate')),
        )
      ],
    );
  }
}
