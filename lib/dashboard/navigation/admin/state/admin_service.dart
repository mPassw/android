import 'dart:convert';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/admin/model/smtp_settings.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';

class AdminService {
  static const getUsersListPath = "/users";

  static const getSMTPSettingsPath = "/smtp";
  static const patchSMTPSettingsPath = "/smtp";
  static const postTestEmailPath = "/smtp";

  static const patchUserVerificationPath = "/users/{}/verification";
  static const patchUserRolePath = "/users/{}/admin";

  static Future<List<User>> getUsersList() async {
    final response =
        await PasswordsService.request(getUsersListPath, "GET", null, null);

    final dynamic jsonResponse = jsonDecode(response.body);

    List<User> usersList = (jsonResponse as List<dynamic>)
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();

    return usersList;
  }

  static Future<SMTPSettings> getSMTPSettings() async {
    final response =
        await PasswordsService.request(getSMTPSettingsPath, "GET", null, null);

    final dynamic jsonResponse = jsonDecode(response.body);

    SMTPSettings smtpSettings = SMTPSettings.fromJson(jsonResponse);

    return smtpSettings;
  }

  static Future<void> patchSMTPSettings(SMTPSettings smtpSettings) async {
    final headers = {
      "Content-Type": "application/json",
    };
    await PasswordsService.request(patchSMTPSettingsPath, "PATCH", headers,
        SMTPSettings.toJson(smtpSettings));
  }

  static Future<void> postTestEmail(String recipientEmail) async {
    final headers = {
      "Content-Type": "application/json",
    };

    await PasswordsService.request(
        postTestEmailPath, "POST", headers, {"recipient": recipientEmail});
  }

  static Future<void> patchUserVerification(String userId) async {
    String path = patchUserVerificationPath.replaceFirst("{}", userId);

    await PasswordsService.request(path, "PATCH", null, null);
  }

  static Future<void> patchUserRole(String userId) async {
    String path = patchUserRolePath.replaceFirst("{}", userId);

    await PasswordsService.request(path, "PATCH", null, null);
  }
}
