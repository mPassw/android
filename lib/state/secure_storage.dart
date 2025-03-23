import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mpass/service/http_service.dart';

class SecureStorage {
  SecureStorage._privateConstructor();

  static final SecureStorage instance = SecureStorage._privateConstructor();

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  final _serverUrlKey = 'serverUrl';
  final _emailKey = 'email';
  final _masterPasswordKey = 'masterPassword';
  final _jwtTokenKey = 'jwtToken';
  final _derivedKey = 'derivedKey';
  final _salt = 'salt';

  Future<void> setServerUrl(String url) async {
    await _storage.write(key: _serverUrlKey, value: url);
  }

  Future<String> getServerUrl() async {
    final url = await _storage.read(key: _serverUrlKey);
    if (url == null || url.isEmpty) {
      throw UnauthorizedException('Server URL not found in secure storage');
    }
    return url;
  }

  Future<void> setEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String> getEmail() async {
    final email = await _storage.read(key: _emailKey);
    if (email == null || email.isEmpty) {
      throw UnauthorizedException('Email not found in secure storage');
    }
    return email;
  }

  Future<void> setMasterPassword(String password) async {
    await _storage.write(key: _masterPasswordKey, value: password);
  }

  Future<String> getMasterPassword() async {
    final password = await _storage.read(key: _masterPasswordKey);
    if (password == null || password.isEmpty) {
      throw UnauthorizedException(
          'Master password not found in secure storage');
    }
    return password;
  }

  Future<void> setJwtToken(String token) async {
    await _storage.write(key: _jwtTokenKey, value: token);
  }

  Future<String> getJwtToken() async {
    final token = await _storage.read(key: _jwtTokenKey);
    if (token == null || token.isEmpty) {
      throw UnauthorizedException('JWT Token not found in secure storage');
    }
    return token;
  }

  Future<void> setDerivedKey(String derivedKey) async {
    await _storage.write(key: _derivedKey, value: derivedKey);
  }

  Future<String> getDerivedKey() async {
    final derivedKey = await _storage.read(key: _derivedKey);
    if (derivedKey == null || derivedKey.isEmpty) {
      throw UnauthorizedException('Derived key not found in secure storage');
    }
    return derivedKey;
  }

  Future<void> setSalt(String salt) async {
    await _storage.write(key: _salt, value: salt);
  }

  Future<String> getSalt() async {
    final salt = await _storage.read(key: _salt);
    if (salt == null || salt.isEmpty) {
      throw UnauthorizedException('Salt not found in secure storage');
    }
    return salt;
  }

  Future<void> removeServerUrl() async {
    await _storage.delete(key: _serverUrlKey);
  }

  Future<void> removeDerivedKey() async {
    await _storage.delete(key: _derivedKey);
  }

  Future<void> removeSalt() async {
    await _storage.delete(key: _salt);
  }

  Future<void> removeJwtToken() async {
    await _storage.delete(key: _jwtTokenKey);
  }

  Future<void> removeMasterPassword() async {
    await _storage.delete(key: _masterPasswordKey);
  }

  Future<void> removeEmail() async {
    await _storage.delete(key: _emailKey);
  }
}
