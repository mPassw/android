import 'package:flutter/material.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/generator/state/password_generator.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:provider/provider.dart';

class UsernameGeneratorTab extends StatefulWidget {
  const UsernameGeneratorTab({super.key});

  @override
  UsernameGeneratorTabState createState() => UsernameGeneratorTabState();
}

class UsernameGeneratorTabState extends State<UsernameGeneratorTab> {
  void generate() {
    try {
      PasswordsGeneratorState passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      String typeOfUsername = passwordsGeneratorState.typeOfUsername;
      if (typeOfUsername == 'Username') {
        UsernameParams usernameParams = passwordsGeneratorState.usernameParams;
        List<String> wordsList = passwordsGeneratorState.wordsList;
        String generatedValue =
            PasswordGenerator.generateUsername(usernameParams, wordsList);
        passwordsGeneratorState.setGeneratedUsername(generatedValue);
      }
      if (typeOfUsername == 'Email') {
        EmailParams emailParams = passwordsGeneratorState.emailParams;
        if (!CustomUtils.isValidEmail(emailParams.email)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(Sonner(message: "Invalid email"));
          return;
        }
        String generatedValue = PasswordGenerator.generateEmail(emailParams);
        passwordsGeneratorState.setGeneratedEmail(generatedValue);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context);
    UsernameParams usernameParams = passwordsGeneratorState.usernameParams;
    EmailParams emailParams = passwordsGeneratorState.emailParams;
    String typeOfUsername = passwordsGeneratorState.typeOfUsername;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: DropdownButton<String>(
              value: typeOfUsername,
              hint: Text('Select an option'),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                passwordsGeneratorState.setTypeOfUsername(newValue);
              },
              items: ['Username', 'Email']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
            ),
          ),
          if (typeOfUsername == 'Username')
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Include Number"),
                      Switch(
                        value: usernameParams.includeNumber,
                        onChanged: (value) {
                          passwordsGeneratorState.setUsernameParams(
                              usernameParams.copy(includeNumber: value));
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
                        value: usernameParams.capitalize,
                        onChanged: (value) {
                          passwordsGeneratorState.setUsernameParams(
                              usernameParams.copy(capitalize: value));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (typeOfUsername == 'Email')
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: TextField(
                    controller: TextEditingController(text: emailParams.email),
                    onChanged: (value) {
                      passwordsGeneratorState
                          .setEmailParams(emailParams.copy(email: value));
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail),
                      border: OutlineInputBorder(),
                      labelText: "Email",
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(onPressed: generate, child: Text('Generate')),
          )
        ],
      ),
    );
  }
}
