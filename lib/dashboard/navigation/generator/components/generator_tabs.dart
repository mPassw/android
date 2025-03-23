import 'package:flutter/material.dart';
import 'package:mpass/dashboard/navigation/generator/components/generated_history_tab.dart';
import 'package:mpass/dashboard/navigation/generator/components/passphrase_generator_tab.dart';
import 'package:mpass/dashboard/navigation/generator/components/password_generator_tab.dart';
import 'package:mpass/dashboard/navigation/generator/components/username_generator_tab.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:provider/provider.dart';

class GeneratorTabs extends StatefulWidget {
  const GeneratorTabs({super.key});

  @override
  GeneratorTabsState createState() => GeneratorTabsState();
}

class GeneratorTabsState extends State<GeneratorTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context, listen: false);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = passwordsGeneratorState.tabIndex;
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        passwordsGeneratorState.setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context);
    String selectedValue = passwordsGeneratorState.typeOfPassword;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Passwords'),
            Tab(text: 'Username'),
            Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: DropdownButton<String>(
                          value: selectedValue,
                          hint: Text('Select an option'),
                          onChanged: (String? newValue) {
                            if (newValue == null) return;
                            passwordsGeneratorState.setTypeOfPassword(newValue);
                          },
                          items: ['Password', 'Passphrase']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          isExpanded: true,
                        ),
                      ),
                      if (selectedValue == 'Password') PasswordGeneratorTab(),
                      if (selectedValue == 'Passphrase')
                        PassphraseGeneratorTab(),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                child: UsernameGeneratorTab(),
              ),
              GeneratedHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}
