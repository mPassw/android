import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/divider_0.dart';
import 'package:mpass/components/skeletons/user_card_skeleton.dart';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/admin/components/smtp_settings_dialog.dart';
import 'package:mpass/dashboard/navigation/admin/components/smtp_test_dialog.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_state.dart';
import 'package:mpass/dashboard/navigation/admin/components/user_edit_dialog.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Future<void> _refreshUsers() async {
    AdminState adminState = Provider.of<AdminState>(context, listen: false);
    try {
      await adminState.fetchUserList();
    } catch (error) {
      if (!mounted) return;
      if (error is Exception) HttpService.parseException(context, error);
    } finally {
      adminState.setIsUsersListLoading(false);
    }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AdminState>(context, listen: false)
        .setIsUsersListLoadingPassive(true);
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        await _refreshUsers();
      } catch (error) {
        if (!mounted) return;
        if (error is Exception) HttpService.parseException(context, error);
      }
    });
  }

  void showSmtpSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
          child: SmtpSettingsDialogContent(),
        );
      },
    );
  }

  void showUserEditDialog(BuildContext context, User currentUser) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
          child: UserEditDialogContent(currentUser: currentUser),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = Provider.of<AdminState>(context);
    final displayedUsersList = adminState.userList;
    final isLoading = adminState.isUsersListLoading;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(children: [
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
                        showSmtpSettingsDialog(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings,
                              size: 28,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "SMTP Settings",
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
                      onTap: () {
                        showSendTestEmailDialog(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.outgoing_mail,
                              size: 28,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "SMTP Test",
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
          ])),
      // Top header
      Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Material(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1.0),
                left: BorderSide(color: Colors.grey[800]!, width: 1.0),
                right: BorderSide(color: Colors.grey[800]!, width: 1.0),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.group_outlined),
                  SizedBox(width: 8),
                  Text(
                    "Users",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              child: RefreshIndicator(
                onRefresh: _refreshUsers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    if (isLoading)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return UserCardSkeleton();
                        },
                      )
                    else if (displayedUsersList.isEmpty)
                      Center(
                        child: Text(
                          'No users registered. Swipe down to refresh.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedUsersList.length,
                        itemBuilder: (context, index) {
                          final user = displayedUsersList[index];
                          return InkWell(
                            onTap: () {
                              showUserEditDialog(context, user);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              user.admin == true
                                                  ? Icons
                                                      .admin_panel_settings_outlined
                                                  : Icons.person_outline,
                                              size: 36,
                                            ),
                                            SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start, // Align children to the left
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      user.email ?? 'No Email',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Badge(
                                                      label: Text(
                                                        user.admin == true
                                                            ? "Admin"
                                                            : "User",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      backgroundColor:
                                                          user.admin == true
                                                              ? Colors.red[900]!
                                                              : Colors
                                                                  .grey[800]!,
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              6, 1, 6, 1),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Badge(
                                                      label: Text(
                                                        user.verified == true
                                                            ? "Verified"
                                                            : "Unverified",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      backgroundColor: user
                                                                  .verified ==
                                                              true
                                                          ? Colors.green[900]!
                                                          : Colors.grey[800]!,
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              6, 1, 6, 1),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ]),
                                  Row(
                                    children: [
                                      Badge.count(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        textColor: theme.colorScheme.onPrimary,
                                        count: user.passwords ?? 0,
                                        child: Icon(Icons.password),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ])));
  }
}
