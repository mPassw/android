import 'package:mpass/dashboard/navigation/passwords/model/password.dart';

class UpdateUsernameParams {
  String? email;
  String? username;
  String? salt;
  String? verifier;
  String? code;
  List<Password> passwords;

  UpdateUsernameParams({
    this.email,
    this.username,
    this.salt,
    this.verifier,
    this.code,
    List<Password>? passwords,
  }) : passwords = passwords ?? [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['username'] = username;
    data['salt'] = salt;
    data['verifier'] = verifier;
    data['code'] = code;
    data['passwords'] = passwords.map((password) => password.toJson()).toList();
    return data;
  }
}
