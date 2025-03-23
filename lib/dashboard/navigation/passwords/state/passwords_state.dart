import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/state/secure_storage.dart';

import 'passwords_service.dart';

class PasswordsState extends ChangeNotifier {
  List<Password> _passwordList = [];
  List<Password> get passwordList => _passwordList;

  String _searchFilter = "";
  String get searchFilter => _searchFilter;

  String _trashFilter = "";
  String get trashFilter => _trashFilter;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void setSearchFilter(String newValue) {
    _searchFilter = newValue;
    notifyListeners();
  }

  void setTrashFilter(String newValue) {
    _trashFilter = newValue;
    notifyListeners();
  }

  void setPasswordList(List<Password> newValue) {
    _passwordList = newValue;
    notifyListeners();
  }

  void setIsLoading(bool newValue) {
    _isLoading = newValue;
    notifyListeners();
  }

  Future<void> addPassword(Password password) async {
    String hexEncryptionKey = await getEncryptionKey();
    Password encryptedPassword =
        await PasswordsService.encryptPassword(password, hexEncryptionKey);
    await PasswordsService.postPassword(encryptedPassword);
    await fetchPasswords();
  }

  Future<void> updatePassword(Password password) async {
    String hexEncryptionKey = await getEncryptionKey();
    Password encryptedPassword =
        await PasswordsService.encryptPassword(password, hexEncryptionKey);
    await PasswordsService.patchPassword(encryptedPassword);
    await fetchPasswords();
  }

  Future<void> deletePassword(String passwordId) async {
    await PasswordsService.deletePassword(passwordId);
    await fetchPasswords();
  }

  Future<void> deleteAllPasswords() async {
    await PasswordsService.deleteAllPasswords();
    await fetchPasswords();
  }

  Future<void> fetchPasswords() async {
    setIsLoading(true);

    final passwords = await PasswordsService.getPasswords();
    _passwordList = passwords;

    try {
      await PasswordsService.savePasswordList(passwords);
    } catch (e) {}
  }

  Future<void> fetchLocalPasswords() async {
    setIsLoading(true);

    final passwords = await PasswordsService.loadLocalPasswordList();
    _passwordList = passwords;
  }

  Future<String> getEncryptionKey() async {
    SecureStorage secureStorage = SecureStorage.instance;
    return await secureStorage.getDerivedKey();
  }
}
