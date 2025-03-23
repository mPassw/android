import 'package:flutter/material.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/account/model/user.dart';
import 'package:mpass/dashboard/navigation/account/model/update_username_params.dart';
import 'package:mpass/dashboard/navigation/account/state/user_service.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/service/http_service.dart';

class UserState extends ChangeNotifier {
  User _user = User();
  User get user => _user;

  bool _codeSent = false;
  bool get codeSent => _codeSent;

  setUser(User newValue) {
    _user = newValue;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    User newUser = await UserService.getUser();
    setUser(newUser);
  }

  Future<void> deauthorizeSessions() async {
    await UserService.postSessions();
  }

  Future<void> changeUser(UpdateUsernameParams params) async {
    await UserService.patchUser(params);
  }

  Future<void> checkEmailAvailability(String email) async {
    await UserService.postCheckEmail(email);
  }

  Future<void> sendVerificationCode() async {
    await UserService.getRequestCode();
    _codeSent = true;
  }

  Future<void> sendUpdateCode() async {
    await UserService.getUpdateCode();
  }

  Future<void> verifyCode(String code) async {
    await UserService.postVerifyCode(code);
  }

  Future<List<Password>> reEncryptPasswords(List<Password> passwordList,
      String hexEncryptionKey, String hexDecryptionKey) async {
    return await Future.wait(
      passwordList.map((element) async {
        Password decryptedPassword = element.copy();
        if (element.decrypted == false) {
          decryptedPassword =
              await PasswordsService.decryptPassword(element, hexDecryptionKey);
        }
        return await PasswordsService.encryptPassword(
            decryptedPassword, hexEncryptionKey);
      }),
    );
  }

  Future<void> sendCode(
      BuildContext context, Future<void> Function() sendCodeFunction) async {
    try {
      await sendCodeFunction();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(Sonner(message: "Code sent"));
    } catch (error) {
      if (!context.mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to send code"));
      }
    }
  }
}

