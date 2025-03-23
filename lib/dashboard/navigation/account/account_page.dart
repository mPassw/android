import 'package:flutter/material.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/components/divider_0.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/components/title_value.dart';
import 'package:mpass/dashboard/navigation/account/components/change_email_dialog.dart';
import 'package:mpass/dashboard/navigation/account/components/change_master_password_dialog.dart';
import 'package:mpass/dashboard/navigation/account/components/change_username_dialog.dart';
import 'package:mpass/dashboard/navigation/account/components/email_verification.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/dialog_utils.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _logout(BuildContext context) async {
    try {
      LoadingDialog.show(context);
      await AuthorizationService.logout(context);
    } catch (e) {
      if (!context.mounted) return;
      if (e is CustomException) {
        ScaffoldMessenger.of(context).showSnackBar(Sonner(message: e.message));
      }
      LoadingDialog.hide(context);
    }
  }

  void showChangeEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
          child: ChangeEmailDialogContent(),
        );
      },
    );
  }

  void showChangeUsernameDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
          child: ChangeUsernameDialogContent(),
        );
      },
    );
  }

  void showChangeMasterPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
          child: ChangeMasterPasswordDialogContent(),
        );
      },
    );
  }

  Future<void> _deleteAllPasswords() async {
    try {
      DialogUtils.showConfirmationDialog(context, "Delete All Passwords",
              "Are you sure you want to delete all passwords?")
          .then((value) async {
        if (value == true && mounted) {
          LoadingDialog.show(context);
          final passwordsState = Provider.of<PasswordsState>(context);
          await passwordsState.deleteAllPasswords();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(Sonner(message: "Passwords deleted"));
          LoadingDialog.hide(context);
        }
      });
    } catch (error) {
      if (error is Exception) HttpService.parseException(context, error);
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  Future<void> _deauthorizeSessions() async {
    try {
      DialogUtils.showConfirmationDialog(context, "Deauthorize Sessions",
              "Are you sure you want to deauthorize all sessions?")
          .then((value) async {
        if (value == true && mounted) {
          LoadingDialog.show(context);
          final userState = Provider.of<UserState>(context, listen: false);
          await userState.deauthorizeSessions();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(Sonner(message: "Sessions deauthorized"));
          _logout(context);
        }
      });
    } catch (error) {
      if (error is Exception) HttpService.parseException(context, error);
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  Future<void> _deleteAccount() async {}

  @override
  Widget build(BuildContext context) {
    final passwordsState = Provider.of<PasswordsState>(context);
    final userState = Provider.of<UserState>(context);

    final email = userState.user.email ?? '';
    final username = userState.user.username ?? '';
    final totalPasswords = passwordsState.passwordList.length;

    final isVerified = userState.user.verified;

    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Card.outlined(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoItem(title: 'Email', value: email),
                              SizedBox(height: 16),
                              InfoItem(title: 'Username', value: username),
                              SizedBox(height: 16),
                              InfoItem(
                                title: 'Total Passwords Saved',
                                value: totalPasswords.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.grey[800]!,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                showChangeEmailDialog();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 28,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Change Email",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DividerNoMargin(color: Colors.grey[800]!),
                            InkWell(
                              onTap: () {
                                showChangeUsernameDialog();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle_outlined,
                                      size: 28,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Change Username",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DividerNoMargin(color: Colors.grey[800]!),
                            InkWell(
                              onTap: () {
                                showChangeMasterPasswordDialog();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.key,
                                      size: 28,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Change Master Password",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isVerified == false)
                              Column(
                                children: [
                                  DividerNoMargin(color: Colors.grey[800]!),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const EmailVerification()));
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.verified_user_outlined,
                                            size: 28,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            "Verify Email",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.grey[800]!,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            _logout(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 28,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Sign Out",
                                  style: TextStyle(
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
                    SizedBox(height: 8),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Danger Zone",
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _deauthorizeSessions();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.gpp_maybe_outlined,
                                      size: 28,
                                      color: Colors.red[900],
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Deauthorize Sessions",
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
                            DividerNoMargin(color: Colors.red[900]),
                            InkWell(
                              onTap: _deleteAllPasswords,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.password,
                                      size: 28,
                                      color: Colors.red[900],
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Delete All Passwords",
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
                            DividerNoMargin(color: Colors.red[900]),
                            InkWell(
                              onTap: _deleteAccount,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle_outlined,
                                      size: 28,
                                      color: Colors.red[900],
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      "Delete Account",
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
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    ));
  }
}
