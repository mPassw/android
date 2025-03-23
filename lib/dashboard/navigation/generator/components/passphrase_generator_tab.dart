import 'package:flutter/material.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/generator/state/password_generator.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:provider/provider.dart';

class PassphraseGeneratorTab extends StatefulWidget {
  const PassphraseGeneratorTab({super.key});

  @override
  State<PassphraseGeneratorTab> createState() => _PassphraseGeneratorTabState();
}

class _PassphraseGeneratorTabState extends State<PassphraseGeneratorTab> {
  void generatePassphrase() {
    try {
      PasswordsGeneratorState passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      PassphraseParams passphraseParams =
          passwordsGeneratorState.passphraseParams;
      List<String> wordsList = passwordsGeneratorState.wordsList;
      String generatedValue =
          PasswordGenerator.generatePassphrase(passphraseParams, wordsList);
      passwordsGeneratorState.setGeneratedPassphrase(generatedValue);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Failed to generate"));
    }
  }

  @override
  Widget build(BuildContext context) {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context);
    PassphraseParams passphraseParams =
        passwordsGeneratorState.passphraseParams;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Passphrase Length"),
              Text("${passphraseParams.passphraseLength}"),
            ],
          ),
        ),
        Slider(
          value: passphraseParams.passphraseLength.toDouble(),
          onChanged: (value) {
            passwordsGeneratorState.setPassphraseParams(
                passphraseParams.copy(passphraseLength: value.toInt()));
          },
          min: 4,
          max: 16,
          divisions: 16,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Include Number"),
              Switch(
                value: passphraseParams.includeNumber,
                onChanged: (value) {
                  passwordsGeneratorState.setPassphraseParams(
                      passphraseParams.copy(includeNumber: value));
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Capitalize"),
              Switch(
                value: passphraseParams.capitalize,
                onChanged: (value) {
                  passwordsGeneratorState.setPassphraseParams(
                      passphraseParams.copy(capitalize: value));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: TextField(
            controller: TextEditingController(text: passphraseParams.separator),
            onChanged: (value) {
              passwordsGeneratorState
                  .setPassphraseParams(passphraseParams.copy(separator: value));
            },
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.emergency),
              border: OutlineInputBorder(),
              labelText: "Separator",
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: FilledButton(
              onPressed: generatePassphrase, child: Text('Generate')),
        )
      ],
    );
  }
}
