import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/admin/model/smtp_settings.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_service.dart';

class AdminState extends ChangeNotifier {
  List<User> _userList = [];
  List<User> get userList => _userList;

  SMTPSettings _smtpSettings = SMTPSettings();
  SMTPSettings get smtpSettings => _smtpSettings;

  bool _isUsersListLoading = false;
  bool get isUsersListLoading => _isUsersListLoading;

  void setIsUsersListLoading(bool newValue) {
    _isUsersListLoading = newValue;
    notifyListeners();
  }

  void setIsUsersListLoadingPassive(bool newValue) {
    _isUsersListLoading = newValue;
  }

  setUserList(List<User> newValue) {
    _userList = newValue;
    notifyListeners();
  }

  setSMTPSettings(SMTPSettings newValue) {
    _smtpSettings = newValue;
    notifyListeners();
  }

  Future<void> fetchUserList() async {
    setIsUsersListLoading(true);

    final users = await AdminService.getUsersList();
    _userList = users;
  }

  Future<void> fetchSMTPSettings() async {
    final smtpSettings = await AdminService.getSMTPSettings();
    _smtpSettings = smtpSettings;
  }

  Future<void> updateSMTPSettings(SMTPSettings smtpSettings) async {
    await AdminService.patchSMTPSettings(smtpSettings);
  }

  Future<void> sendTestEmail(String recipientEmail) async {
    await AdminService.postTestEmail(recipientEmail);
  }

  Future<void> toggleUserVerification(String userId) async {
    await AdminService.patchUserVerification(userId);
    List<User> newList = _userList
        .map((user) => user.id == userId
            ? user.copy(verified: user.verified == true ? false : true)
            : user)
        .toList();
    _userList = newList;
    notifyListeners();
  }

  Future<void> toggleUserRole(String userId) async {
    await AdminService.patchUserRole(userId);
    List<User> newList = _userList
        .map((user) => user.id == userId
            ? user.copy(admin: user.admin == true ? false : true)
            : user)
        .toList();
    _userList = newList;
    notifyListeners();
  }
}
