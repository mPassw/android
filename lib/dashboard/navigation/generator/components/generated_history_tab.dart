import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/skeletons/skeleton.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_header.dart';
import 'package:mpass/dashboard/navigation/passwords/state/dialog_utils.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:provider/provider.dart';

class GeneratedHistoryTab extends StatefulWidget {
  const GeneratedHistoryTab({super.key});

  @override
  State<GeneratedHistoryTab> createState() => _GeneratedHistoryTabState();
}

class _GeneratedHistoryTabState extends State<GeneratedHistoryTab> {
  List<GeneratedValue> _generatedHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      PasswordsGeneratorState passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      List<GeneratedValue> values = await passwordsGeneratorState.getHistory();
      if (mounted) {
        setState(() {
          _generatedHistory = values.reversed.toList();
          isLoading = false;
        });
        decryptHistory();
      }
    });
  }

  Future<void> decryptHistory() async {
    try {
      SecureStorage secureStorage = SecureStorage.instance;
      final hexEncryptionKey = await secureStorage.getDerivedKey();
      for (int i = 0; i < _generatedHistory.length; i++) {
        final item = _generatedHistory[i];
        if (item.decrypted == false) {
          String? decrypted =
              await PasswordsService.decryptText(item.value, hexEncryptionKey);
          setState(() {
            _generatedHistory[i] =
                _generatedHistory[i].copy(value: decrypted, decrypted: true);
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to decrypt passwords"),
        ));
      }
    }
  }

  Future<void> _deleteButtonOnPressed(BuildContext context) async {
    DialogUtils.showConfirmationDialog(context, "Delete History",
            "Are you sure you want to permanently delete history?")
        .then((value) async {
      if (value == true && context.mounted) {
        await _clearHistory(context);
      }
    });
  }

  Future<void> _clearHistory(BuildContext context) async {
    PasswordsGeneratorState passwordsGeneratorState =
        Provider.of<PasswordsGeneratorState>(context, listen: false);

    await passwordsGeneratorState.clearHistory();

    if (context.mounted) {
      setState(() {
        _generatedHistory = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("History cleared"),
      ));
    }
  }

  @override
  void dispose() {
    _generatedHistory = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        children: [
          PasswordsHeader(
              title: "History",
              icon: Icons.history,
              button: TextButton.icon(
                onPressed: () {
                  _deleteButtonOnPressed(context);
                },
                label: Text(
                  "Clear History",
                  style: TextStyle(color: Colors.red[700]!),
                ),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[700]!,
                ),
              )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Material(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey[800]!, width: 1.0),
                      right: BorderSide(color: Colors.grey[800]!, width: 1.0),
                      bottom: BorderSide(color: Colors.grey[800]!, width: 1.0),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: isLoading ? 10 : _generatedHistory.length,
                    itemBuilder: (context, index) {
                      final generatedValue = isLoading
                          ? GeneratedValue()
                          : _generatedHistory[index];
                      return InkWell(
                          onTap: () {
                            CustomUtils.copyToClipboard(
                                generatedValue.value, context);
                          },
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (generatedValue.decrypted == true)
                                    Text.rich(
                                      TextSpan(
                                        children: generatedValue.value
                                            .split('')
                                            .map((char) {
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
                                            text: char,
                                            style: TextStyle(color: color),
                                          );
                                        }).toList(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  if (generatedValue.decrypted == false)
                                    Skeleton(
                                      element: Container(
                                        width: 200,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  if (isLoading == false)
                                    Text(
                                      generatedValue.createdAt,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (isLoading == true)
                                    Skeleton(
                                      element: Container(
                                        width: 120,
                                        height: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              )));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
