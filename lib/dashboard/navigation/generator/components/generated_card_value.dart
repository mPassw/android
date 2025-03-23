import 'package:flutter/material.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:provider/provider.dart';

class GeneratedCardValue extends StatefulWidget {
  const GeneratedCardValue({super.key});

  @override
  State<GeneratedCardValue> createState() => _GeneratedCardValueState();
}

class _GeneratedCardValueState extends State<GeneratedCardValue> {
  bool _isSaving = false;

  void copyToClipboard(String value, BuildContext context) async {
    try {
      setState(() {
        _isSaving = true;
      });
      PasswordsGeneratorState passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      CustomUtils.copyToClipboard(value, context);
      await passwordsGeneratorState
          .addToHistory(GeneratedValue(value: value, decrypted: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to copy to clipboard"));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context);
    String cardValue = passwordsGeneratorState.cardValue;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: _isSaving ? null : () => copyToClipboard(cardValue, context),
            borderRadius: BorderRadius.circular(12),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.grey.withValues(alpha: 0.2);
              }
              return null;
            }),
            child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 100),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Text.rich(
                        TextSpan(
                          children: cardValue.split('').map((char) {
                            Color color;
                            if (RegExp(r'[0-9]').hasMatch(char)) {
                              color = Colors.blue[800]!;
                            } else if (RegExp(r'[!@#$%^&*()_+]')
                                .hasMatch(char)) {
                              color = Colors.red[800]!;
                            } else {
                              color = Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color ??
                                  Colors.black;
                            }
                            return TextSpan(
                                text: char, style: TextStyle(color: color));
                          }).toList(),
                        ),
                        textAlign: TextAlign.center,
                      )),
                    ],
                  ),
                ))),
      ),
    );
  }
}
