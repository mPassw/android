import 'dart:convert';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/account/model/update_username_params.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/service/http_service.dart';

class UserService {
  static const getUserPath = "/users/@me";
  static const postSessionsPath = "/users/@me/sessions";
  static const patchUserPath = "/users/@me";
  static const postCheckEmailPath = "/users/check";
  static const getRequestCodePath = "/smtp/@me";
  static const postVerifyCodePath = "/users/@me/verification";

  static Future<User> getUser() async {
    final response =
        await PasswordsService.request(getUserPath, "GET", null, null);

    final dynamic jsonResponse = jsonDecode(response.body);

    User user = User.fromJson(jsonResponse);
    return user;
  }

  static Future<void> postSessions() async {
    await PasswordsService.request(postSessionsPath, "POST", null, null);
  }

  static Future<void> patchUser(UpdateUsernameParams params) async {
    final headers = {
      "Content-Type": "application/json",
    };
    await PasswordsService.request(
        patchUserPath, "PATCH", headers, params.toJson());
  }

  static Future<void> postCheckEmail(String email) async {
    final headers = {
      "Content-Type": "application/json",
    };
    final response = await PasswordsService.request(
        postCheckEmailPath, "POST", headers, {"email": email});

    final dynamic jsonResponse = jsonDecode(response.body);

    final isEmailAvailable = jsonResponse["isEmailAvailable"];

    if (isEmailAvailable == false) {
      throw ConflictException("Email already exists");
    }
  }

  static Future<void> getRequestCode() async {
    await PasswordsService.request(
        "$getRequestCodePath?Type=Verification", "GET", null, null);
  }

  static Future<void> postVerifyCode(String code) async {
    final headers = {
      "Content-Type": "application/json",
    };
    await PasswordsService.request(
        postVerifyCodePath, "POST", headers, {"code": code});
  }

  static Future<void> getUpdateCode() async {
    await PasswordsService.request(
        "$getRequestCodePath?Type=AccountUpdate", "GET", null, null);
  }
}
