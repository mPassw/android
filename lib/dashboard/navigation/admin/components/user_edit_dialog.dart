import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mpass/components/divider_0.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/components/title_value.dart';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class UserEditDialogContent extends StatefulWidget {
  const UserEditDialogContent({super.key, this.currentUser});

  final User? currentUser;

  @override
  State<UserEditDialogContent> createState() => _UserEditDialogContentState();
}

class _UserEditDialogContentState extends State<UserEditDialogContent> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser ?? User();
  }

  Future<void> _toggleUserVerification() async {
    try {
      LoadingDialog.show(context);
      final adminState = Provider.of<AdminState>(context, listen: false);
      await adminState.toggleUserVerification(_user.id.toString());
      setState(() {
        _user = _user.copy(verified: _user.verified == true ? false : true);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Verification toggled"));
      LoadingDialog.hide(context);
    } catch (error) {
      if (error is Exception) HttpService.parseException(context, error);
    } finally {
      LoadingDialog.hide(context);
    }
  }

  Future<void> _toggleUserRole() async {
    try {
      LoadingDialog.show(context);
      final adminState = Provider.of<AdminState>(context, listen: false);
      await adminState.toggleUserRole(_user.id.toString());
      setState(() {
        _user = _user.copy(admin: _user.admin == true ? false : true);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(Sonner(message: "Role toggled"));
      LoadingDialog.hide(context);
    } catch (error) {
      log(error.toString());
      if (error is Exception) HttpService.parseException(context, error);
    } finally {
      LoadingDialog.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    UserState userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.user.id.toString();
    final isCurrentUser = _user.id == userId;

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'User Edit',
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      elevation: 10,
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Badge(
                                    label: Text(
                                      _user.admin == true ? "Admin" : "User",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _user.admin == true
                                        ? Colors.red[900]!
                                        : Colors.grey[800]!,
                                    padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                                  ),
                                  SizedBox(width: 8),
                                  Badge(
                                    label: Text(
                                      _user.verified == true
                                          ? "Verified"
                                          : "Unverified",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _user.verified == true
                                        ? Colors.green[900]!
                                        : Colors.grey[800]!,
                                    padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                                  ),
                                ]),
                                SizedBox(height: 16),
                                InfoItem(
                                    title: "ID", value: _user.id.toString()),
                                SizedBox(height: 16),
                                InfoItem(
                                    title: "Email",
                                    value: _user.email ?? 'none'),
                                SizedBox(height: 16),
                                InfoItem(
                                    title: "Username",
                                    value: _user.username ?? 'none'),
                                SizedBox(height: 16),
                                InfoItem(
                                    title: "Passwords Saved",
                                    value: _user.passwords.toString()),
                              ])),
                    )),
                SizedBox(height: 12),
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
                    elevation: 10,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: isCurrentUser == true
                              ? null
                              : () {
                                  _toggleUserRole();
                                },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  _user.admin == true
                                      ? Icons.person_outline
                                      : Icons.admin_panel_settings_outlined,
                                  size: 28,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Toggle Role to ${_user.admin == true ? 'User' : 'Admin'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DividerNoMargin(color: Colors.grey[800]),
                        InkWell(
                          onTap: isCurrentUser == true
                              ? null
                              : () {
                                  _toggleUserVerification();
                                },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  _user.verified == true
                                      ? Icons.error_outline
                                      : Icons.check_circle_outlined,
                                  size: 28,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Toggle to ${_user.verified == true ? 'Unverified' : 'Verified'}",
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
