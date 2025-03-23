import 'package:flutter/material.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/dialog_utils.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/custom_utils.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/network_state.dart';
import 'package:provider/provider.dart';

class PasswordDialogContent extends StatefulWidget {
  const PasswordDialogContent({
    super.key,
    required this.dialogTitle,
    required this.currentPassword,
    this.isEditModeEnabled = false,
  });

  final Password currentPassword;
  final String dialogTitle;
  final bool isEditModeEnabled;

  @override
  State<PasswordDialogContent> createState() => _PasswordDialogContentState();
}

class _PasswordDialogContentState extends State<PasswordDialogContent> {
  Password _password = Password();
  bool _obscureText = true;
  bool _editMode = false;

  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _password = widget.currentPassword;
    if (_password.id == null) _editMode = true;
    if (widget.isEditModeEnabled) _editMode = true;
  }

  Future<void> _passwordLoader(
      String successMessage, Future<void> Function() action) async {
    LoadingDialog.show(context);
    await action();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: successMessage));
      LoadingDialog.hide(context);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveButtonOnPressed() async {
    FocusScope.of(context).unfocus();
    if (_password.title == null || _password.title!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Title cannot be empty"));
      return;
    }
    if ((_password.username == null || _password.username!.isEmpty) &&
        (_password.password == null || _password.password!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          Sonner(message: "Username and Password cannot be empty"));
      return;
    }
    PasswordsState passwordsState =
        Provider.of<PasswordsState>(context, listen: false);
    try {
      if (_password.inTrash) {
        await _passwordLoader("Password Restored", () async {
          await passwordsState.updatePassword(_password.copy(inTrash: false));
        });
        return;
      }
      if (_password.id != null) {
        await _passwordLoader("Password Updated", () async {
          await passwordsState.updatePassword(_password);
        });
      } else {
        await _passwordLoader("Password Saved", () async {
          await passwordsState.addPassword(_password);
        });
      }
    } catch (error) {
      if (error is Exception && mounted) {
        HttpService.parseException(context, error);
      }
    } finally {
      passwordsState.setIsLoading(false);
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  Future<void> _deleteButtonOnPressed() async {
    FocusScope.of(context).unfocus();
    final passwordsState = Provider.of<PasswordsState>(context, listen: false);
    try {
      if (!_password.inTrash) {
        await _passwordLoader("Password Moved to Trash", () async {
          await passwordsState.updatePassword(_password.copy(inTrash: true));
        });
      } else {
        DialogUtils.showConfirmationDialog(context, "Delete Password",
                "Are you sure you want to permanently delete this password?")
            .then((value) async {
          if (value == true && mounted) {
            await _passwordLoader("Password Deleted", () async {
              try {
                await passwordsState.deletePassword(_password.id.toString());
              } catch (error) {
                if (error is Exception && mounted) {
                  HttpService.parseException(context, error);
                }
              } finally {
                passwordsState.setIsLoading(false);
              }
            });
          }
        });
      }
    } catch (error) {
      if (error is Exception && mounted) {
        HttpService.parseException(context, error);
      }
    } finally {
      passwordsState.setIsLoading(false);
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = Provider.of<NetworkState>(context).isConnected;
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            widget.dialogTitle,
            style: TextStyle(fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_password.inTrash && _password.id != null && isConnected)
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(
                      "Edit Mode",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _editMode,
                      onChanged: (value) {
                        setState(() {
                          _editMode = value;
                        });
                      },
                    ),
                  ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: TextEditingController(text: _password.title),
                    onChanged: (value) {
                      _password.title = value;
                    },
                    readOnly: !_editMode,
                    autofocus: _editMode,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.topic_outlined),
                      suffixIcon: IconButton(
                          onPressed: () {
                            CustomUtils.copyToClipboard(
                                _password.title ?? "", context);
                          },
                          icon: const Icon(Icons.copy)),
                      border: const OutlineInputBorder(),
                      labelText: "Title",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: TextEditingController(text: _password.username),
                    onChanged: (value) {
                      _password.username = value;
                    },
                    readOnly: !_editMode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.account_circle_outlined),
                      suffixIcon: IconButton(
                          onPressed: () {
                            CustomUtils.copyToClipboard(
                                _password.username ?? "", context);
                          },
                          icon: const Icon(Icons.copy)),
                      border: OutlineInputBorder(),
                      labelText: "Username",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: TextEditingController(text: _password.password),
                    onChanged: (value) {
                      _password.password = value;
                    },
                    readOnly: !_editMode,
                    obscureText: _obscureText,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              onPressed: () {
                                CustomUtils.copyToClipboard(
                                    _password.password ?? "", context);
                              },
                              icon: const Icon(Icons.copy)),
                          IconButton(
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
                        ])),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...List.generate(_password.websites.length, (index) {
                  return Column(children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          _password.websites[index] = value;
                        },
                        readOnly: !_editMode,
                        controller: TextEditingController(
                            text: _password.websites[index]),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "Website URL",
                          prefixIcon: const Icon(Icons.link_outlined),
                          suffixIcon:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                onPressed: () {
                                  CustomUtils.copyToClipboard(
                                      _password.websites[index], context);
                                },
                                icon: const Icon(Icons.copy)),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    _password.websites
                                        .remove(_password.websites[index]);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ]);
                }),
                TextButton.icon(
                    onPressed: !_editMode
                        ? null
                        : () {
                            if (_password.websites.length > 10) {
                              ScaffoldMessenger.of(context).showSnackBar(Sonner(
                                  message: "You can only add 10 websites"));
                              return;
                            }
                            setState(() {
                              _password.websites.add('');
                            });
                          },
                    label: const Text("Add Website"),
                    icon: Icon(Icons.add)),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    keyboardType: TextInputType.text,
                    controller: _tagController,
                    enabled: _editMode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.tag_outlined),
                      border: const OutlineInputBorder(),
                      labelText: "Tag",
                      hintText: "",
                    ),
                  ),
                ),
                TextButton.icon(
                    onPressed: !_editMode
                        ? null
                        : () {
                            if (_password.tags.length > 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Sonner(message: "You can only add 10 tags"));
                              return;
                            }
                            if (_tagController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Sonner(message: "Tag cannot be empty"));
                              return;
                            }
                            if (_password.tags.contains(_tagController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Sonner(message: "Tag already exists"));
                              return;
                            }
                            if (_tagController.text.length > 32) {
                              ScaffoldMessenger.of(context).showSnackBar(Sonner(
                                  message:
                                      "Tag cannot be longer than 32 characters"));
                              return;
                            }

                            setState(() {
                              _password.tags.add(_tagController.text);
                              _tagController.clear();
                            });
                          },
                    label: const Text("Add Tag"),
                    icon: Icon(Icons.add)),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _password.tags
                      .map(
                        (tag) => InputChip(
                          label: Text(tag),
                          onPressed: () {
                            CustomUtils.copyToClipboard(tag, context);
                          },
                          onDeleted: !_editMode
                              ? null
                              : () {
                                  setState(() {
                                    _password.tags.remove(tag);
                                  });
                                },
                        ),
                      )
                      .toList(),
                ),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: TextEditingController(text: _password.note),
                    onChanged: (value) {
                      _password.note = value;
                    },
                    readOnly: !_editMode,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Notes",
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        suffix: IconButton(
                            onPressed: () {
                              CustomUtils.copyToClipboard(
                                  _password.note ?? "", context);
                            },
                            icon: Icon(Icons.copy))),
                  ),
                ),
                const SizedBox(height: 16),
                if (isConnected)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: _editMode || _password.inTrash
                            ? () => _saveButtonOnPressed()
                            : null,
                        label: Text(_password.inTrash ? "Restore" : "Save"),
                        icon: Icon(_password.inTrash
                            ? Icons.restore_outlined
                            : Icons.save_outlined)),
                  ),
                const SizedBox(height: 16),
                if (_password.id != null && isConnected)
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.red[900]!,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: InkWell(
                        onTap: () {
                          _deleteButtonOnPressed();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 28,
                                color: Colors.red[900],
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                _password.inTrash
                                    ? "Delete Password Permanently"
                                    : "Move to Trash",
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}

Future<bool> showPasswordEditDialog(
    BuildContext context, Password password, String title,
    {bool isEditMode = false}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        backgroundColor: Colors.white,
        child: PasswordDialogContent(
            currentPassword: password,
            dialogTitle: title,
            isEditModeEnabled: isEditMode),
      );
    },
  ).then((value) => value ?? false);
}
