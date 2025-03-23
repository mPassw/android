import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/dashboard/navigation/passwords/components/password_dialog.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/dialog_utils.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:provider/provider.dart';

class PasswordCards extends StatefulWidget {
  const PasswordCards({super.key, required this.isTrash});

  final bool isTrash;

  @override
  State<PasswordCards> createState() => PasswordCardsState();
}

class PasswordCardsState extends State<PasswordCards> {
  MethodChannel _channel = const MethodChannel("");

  @override
  void initState() {
    super.initState();
    final isAutofill =
        Provider.of<AutofillState>(context, listen: false).isAutofill;
    if (isAutofill) {
      _channel = MethodChannel(
          Provider.of<AutofillState>(context, listen: false).flutterEngineId ??
              "");
    }
  }

  Future<void> decryptPassword(
      Password encryptedPassword, BuildContext context) async {
    try {
      FocusScope.of(context).unfocus();
      LoadingDialog.show(context);

      PasswordsState passwordsState =
          Provider.of<PasswordsState>(context, listen: false);
      String hexEncryptionKey = await passwordsState.getEncryptionKey();
      Password decryptedPassword = await PasswordsService.decryptPassword(
          encryptedPassword, hexEncryptionKey);

      if (context.mounted) {
        LoadingDialog.hide(context);
        showPasswordEditDialog(context, decryptedPassword, "Edit Password");
      }
    } catch (error) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to decrypt password"),
        ));
      }
    }
  }

  Future<void> autofillChoice(Password password, BuildContext context) async {
    try {
      FocusScope.of(context).unfocus();
      DialogUtils.showConfirmationDialog(context, "Autofill Password",
              "You are about to autofill the password in the current tab. Are you sure you want to continue?")
          .then((value) async {
        if (value == true && context.mounted) {
          LoadingDialog.show(context);

          String hexEncryptionKey =
              await SecureStorage.instance.getDerivedKey();
          Password decryptedPassword = await PasswordsService.decryptPassword(
              password, hexEncryptionKey);

          if (context.mounted) {
            LoadingDialog.hide(context);
            _channel.invokeMethod('authenticationSuccessful', {
              'username': decryptedPassword.username,
              'password': decryptedPassword.password,
            });
          }
        }
      });
    } catch (error) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to decrypt password"),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAutofill = Provider.of<AutofillState>(context).isAutofill;
    final passwordsState = Provider.of<PasswordsState>(context);
    final isTrash = widget.isTrash;
    final searchFilter =
        isTrash ? passwordsState.trashFilter : passwordsState.searchFilter;
    final passwordList = PasswordsService.filteredPasswordList(
            passwordsState.passwordList, searchFilter)
        .where((password) => password.inTrash == isTrash)
        .toList();

    if (passwordList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No passwords available. Swipe down to refresh.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Column(
        children: passwordList.reversed.map((password) {
          return InkWell(
            onTap: () {
              if (isAutofill) {
                autofillChoice(password, context);
              } else {
                decryptPassword(password, context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.network(
                        "https://icons.duckduckgo.com/ip3/${CustomUtils.getDomainFromUrl(password.websites.firstOrNull ?? '')}.ico",
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.language, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              password.title ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 2.0,
                            children: password.tags.take(2).map((tag) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 1.0, horizontal: 8.0),
                                child: Text(
                                  CustomUtils.truncateString(tag, 8),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }
}
