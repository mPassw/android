import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mpass/dashboard/navigation/generator/state/generator_history_service.dart';
import 'package:mpass/dashboard/navigation/generator/state/password_generator.dart';

class PasswordsGeneratorState extends ChangeNotifier {
  String _cardValue = "";
  String get cardValue => _cardValue;

  String _generatedPassword = "password";
  String get generatedPassword => _generatedPassword;

  String _generatedPassphrase = "passphrase";
  String get generatedPassphrase => _generatedPassphrase;

  String _generatedUsername = "username";
  String get generatedUsername => _generatedUsername;

  String _generatedEmail = "email";
  String get generatedEmail => _generatedEmail;

  String _typeOfUsername = "Username";
  String get typeOfUsername => _typeOfUsername;

  String _typeOfPassword = "Password";
  String get typeOfPassword => _typeOfPassword;

  PasswordParams _passwordParams = PasswordParams();
  PasswordParams get passwordParams => _passwordParams;

  PassphraseParams _passphraseParams = PassphraseParams();
  PassphraseParams get passphraseParams => _passphraseParams;

  UsernameParams _usernameParams = UsernameParams();
  UsernameParams get usernameParams => _usernameParams;

  EmailParams _emailParams = EmailParams();
  EmailParams get emailParams => _emailParams;

  List<String> _wordsList = [];
  List<String> get wordsList => _wordsList;

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  Future<void> loadWordList() async {
    String wordsString = await rootBundle.loadString('assets/words.txt');
    _wordsList = wordsString.split('\n').map((word) => word.trim()).toList();
    notifyListeners();
  }

  Future<void> addToHistory(GeneratedValue generatedValue) async {
    await GeneratorHistoryService.addToHistoryFile(generatedValue);
  }

  Future<void> clearHistory() async {
    await GeneratorHistoryService.clearHistory();
  }

  Future<List<GeneratedValue>> getHistory() async {
    return await GeneratorHistoryService.getHistoryFromFile();
  }

  void setCardValue() {
    if (_tabIndex == 0) {
      if (_typeOfPassword == "Password") {
        _cardValue = _generatedPassword;
      }
      if (_typeOfPassword == "Passphrase") {
        _cardValue = _generatedPassphrase;
      }
    }
    if (_tabIndex == 1) {
      if (_typeOfUsername == "Username") {
        _cardValue = _generatedUsername;
      }
      if (_typeOfUsername == "Email") {
        _cardValue = _generatedEmail;
      }
    }
    notifyListeners();
  }

  Future<void> setGeneratedPassword(String newValue) async {
    _generatedPassword = newValue;
    applyToCard(newValue);
  }

  Future<void> setGeneratedPassphrase(String newValue) async {
    _generatedPassphrase = newValue;
    applyToCard(newValue);
  }

  Future<void> setGeneratedUsername(String newValue) async {
    _generatedUsername = newValue;
    applyToCard(newValue);
  }

  Future<void> setGeneratedEmail(String newValue) async {
    _generatedEmail = newValue;
    applyToCard(newValue);
  }

  Future<void> applyToCard(String value) async {
    _cardValue = value;
    notifyListeners();
  }

  void setTypeOfUsername(String newValue) {
    if (_typeOfUsername == newValue) return;
    _typeOfUsername = newValue;
    setCardValue();
  }

  void setTypeOfPassword(String newValue) {
    if (_typeOfPassword == newValue) return;
    _typeOfPassword = newValue;
    setCardValue();
  }

  void setPasswordParams(PasswordParams newValue) {
    _passwordParams = newValue;
    notifyListeners();
  }

  void setPassphraseParams(PassphraseParams newValue) {
    _passphraseParams = newValue;
    notifyListeners();
  }

  void setUsernameParams(UsernameParams newValue) {
    _usernameParams = newValue;
    notifyListeners();
  }

  void setEmailParams(EmailParams newValue) {
    _emailParams = newValue;
    notifyListeners();
  }

  void setTabIndex(int newValue) {
    if (_tabIndex == newValue) return;
    _tabIndex = newValue;
    setCardValue();
  }

  void initializeGeneratedValues(String email) async {
    String generatedPassword =
        PasswordGenerator.generatePassword(passwordParams);
    String generatedPassphrase =
        PasswordGenerator.generatePassphrase(passphraseParams, wordsList);
    String generatedUsername =
        PasswordGenerator.generateUsername(usernameParams, wordsList);
    if (email.isNotEmpty) {
      _emailParams = EmailParams(email: email);
    }
    String generatedEmail = PasswordGenerator.generateEmail(emailParams);

    setGeneratedEmail(generatedEmail);
    setGeneratedUsername(generatedUsername);
    setGeneratedPassphrase(generatedPassphrase);
    setGeneratedPassword(generatedPassword);
  }
}

class PasswordParams {
  final int passwordLength;
  final int minimumNumbers;
  final int minimumSymbols;

  PasswordParams({
    this.passwordLength = 32,
    this.minimumNumbers = 4,
    this.minimumSymbols = 4,
  });

  PasswordParams copy({
    int? passwordLength,
    int? minimumNumbers,
    int? minimumSymbols,
  }) {
    return PasswordParams(
      passwordLength: passwordLength ?? this.passwordLength,
      minimumNumbers: minimumNumbers ?? this.minimumNumbers,
      minimumSymbols: minimumSymbols ?? this.minimumSymbols,
    );
  }
}

class PassphraseParams {
  final int passphraseLength;
  final bool includeNumber;
  final bool capitalize;
  final String separator;

  PassphraseParams({
    this.passphraseLength = 12,
    this.includeNumber = true,
    this.capitalize = true,
    this.separator = "-",
  });

  PassphraseParams copy({
    int? passphraseLength,
    bool? includeNumber,
    bool? capitalize,
    String? separator,
  }) {
    return PassphraseParams(
      passphraseLength: passphraseLength ?? this.passphraseLength,
      includeNumber: includeNumber ?? this.includeNumber,
      capitalize: capitalize ?? this.capitalize,
      separator: separator ?? this.separator,
    );
  }
}

class UsernameParams {
  final bool includeNumber;
  final bool capitalize;

  UsernameParams({
    this.includeNumber = true,
    this.capitalize = true,
  });

  UsernameParams copy({
    bool? includeNumber,
    bool? capitalize,
  }) {
    return UsernameParams(
      includeNumber: includeNumber ?? this.includeNumber,
      capitalize: capitalize ?? this.capitalize,
    );
  }
}

class EmailParams {
  final String email;

  EmailParams({this.email = ""});

  EmailParams copy({String? email}) {
    return EmailParams(email: email ?? this.email);
  }
}

class GeneratedValue {
  final String value;
  final String createdAt;
  final bool decrypted;

  GeneratedValue({
    this.value = "",
    String? createdAt,
    this.decrypted = false,
  }) : createdAt = createdAt ?? _formatDateTime(DateTime.now());

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  factory GeneratedValue.fromJson(Map<String, dynamic> json) {
    return GeneratedValue(
      value: json['value'],
      createdAt: json['createdAt'],
    );
  }

  GeneratedValue copy({
    String? value,
    String? createdAt,
    bool? decrypted,
  }) {
    return GeneratedValue(
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      decrypted: decrypted ?? this.decrypted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "value": value,
      "createdAt": createdAt,
    };
  }
}
