import 'package:flutter/material.dart';
import 'package:mpass/dashboard/navigation/generator/components/generated_card_value.dart';
import 'package:mpass/dashboard/navigation/generator/components/generator_tabs.dart';

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GeneratedCardValue(),
            Expanded(child: GeneratorTabs()),
          ],
        ),
      ),
    );
  }
}
