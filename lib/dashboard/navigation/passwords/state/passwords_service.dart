import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_ce/hive.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/secure_storage.dart';

class PasswordsService {
  static const getPasswordsPath = "/passwords";
  static const postPasswordPath = "/passwords";
  static const patchPasswordPath = "/passwords";
  static const deletePasswordPath = "/passwords/{}";
  static const deleteAllPasswordsPath = "/passwords/bulk";

  static const databaseName = 'mpass_db';
  static const boxName = 'passwordBox';
  static const key = 'passwordList';

  static List<Password> filteredPasswordList(
      List<Password> passwordList, String filter) {
    if (filter.isEmpty) {
      return passwordList;
    }
    final searchTextLower = filter.toLowerCase();
    return passwordList.where((password) {
      bool titleMatch =
          password.title?.toLowerCase().contains(searchTextLower) ?? false;
      bool tagsMatch = password.tags
          .any((tag) => tag.toLowerCase().contains(searchTextLower));
      bool websitesMatch = password.websites
          .any((website) => website.toLowerCase().contains(searchTextLower));
      return titleMatch || tagsMatch || websitesMatch;
    }).toList();
  }

  static Future<List<Password>> getPasswords() async {
    final response = await request(getPasswordsPath, "GET", null, null);

    final dynamic jsonResponse = jsonDecode(response.body);

    List<Password> passwords = (jsonResponse as List<dynamic>)
        .map((item) => Password.fromJson(item as Map<String, dynamic>))
        .toList();
    return passwords;
  }

  static Future<void> postPassword(Password password) async {
    await request(postPasswordPath, "POST",
        {"Content-Type": "application/json"}, password.toJson());
  }

  static Future<void> patchPassword(Password password) async {
    await request(patchPasswordPath, "PATCH",
        {"Content-Type": "application/json"}, password.toJson());
  }

  static Future<void> deletePassword(String passwordId) async {
    String path = deletePasswordPath.replaceAll("{}", passwordId);
    await request(path, "DELETE", null, null);
  }

  static Future<void> deleteAllPasswords() async {
    await request(deleteAllPasswordsPath, "DELETE", null, null);
  }

  static Future<Password> decryptPassword(
      Password encryptedPassword, String hexEncryptionKey) async {
    if (encryptedPassword.decrypted == true) {
      return encryptedPassword.copy();
    }

    final username =
        await decryptText(encryptedPassword.username, hexEncryptionKey);
    final password =
        await decryptText(encryptedPassword.password, hexEncryptionKey);
    final note = await decryptText(encryptedPassword.note, hexEncryptionKey);

    return encryptedPassword.copy(
      username: username,
      password: password,
      note: note,
      decrypted: true,
    );
  }

  static Future<Password> encryptPassword(
      Password password, String hexEncryptionKey) async {
    if (password.decrypted == false) {
      return password.copy();
    }

    String? encryptedUsername =
        await encryptText(password.username, hexEncryptionKey);
    String? encryptedPassword =
        await encryptText(password.password, hexEncryptionKey);
    String? encryptedNote = await encryptText(password.note, hexEncryptionKey);

    return password.copy(
      username: encryptedUsername,
      password: encryptedPassword,
      note: encryptedNote,
      decrypted: false,
    );
  }

  static Future<String?> encryptText(
      String? text, String hexEncryptionKey) async {
    if (text == null || text.isEmpty) {
      return text;
    }

    Argon2id argon2id =
        Argon2id(parallelism: 1, memory: 19456, iterations: 2, hashLength: 32);
    final algoritm = Xchacha20.poly1305Aead();
    final nonce = algoritm.newNonce();
    final salt = AuthorizationService.generateSalt();
    SecretKey secretKey = await argon2id.deriveKey(
        secretKey: SecretKey(hex.decode(hexEncryptionKey)), nonce: salt);

    final plaintextBytes = utf8.encode(text);

    final secretBox = await algoritm.encrypt(
      plaintextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final combinedCipherText = secretBox.cipherText + secretBox.mac.bytes;

    final combinedHex = hex.encode(combinedCipherText);
    final saltHex = hex.encode(salt);
    final nonceHex = hex.encode(nonce);

    return '$combinedHex:$saltHex:$nonceHex';
  }

  static Future<String?> decryptText(
    String? encrypted,
    String hexEncryptionKey,
  ) async {
    if (encrypted == null || encrypted.isEmpty) {
      return encrypted;
    }
    final parts = encrypted.split(':');
    if (parts.length != 3) {
      throw Exception('Invalid encrypted text format.');
    }

    final combined = hex.decode(parts[0]);
    final salt = hex.decode(parts[1]);
    final nonce = hex.decode(parts[2]);

    if (combined.length < 16) {
      throw Exception('Invalid combined ciphertext length.');
    }

    final cipherText = combined.sublist(0, combined.length - 16);
    final macBytes = combined.sublist(combined.length - 16);

    Argon2id argon2id =
        Argon2id(parallelism: 1, memory: 19456, iterations: 2, hashLength: 32);
    final algorithm = Xchacha20.poly1305Aead();

    final derivedKey = await argon2id.deriveKey(
      secretKey: SecretKey(hex.decode(hexEncryptionKey)),
      nonce: salt,
    );

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decryptedBytes =
        await algorithm.decrypt(secretBox, secretKey: derivedKey);

    return utf8.decode(decryptedBytes);
  }

  static request(String path, String method, Map<String, String>? headers,
      Map<String, dynamic>? body) async {
    final secureStorage = SecureStorage.instance;
    final jwtToken = await secureStorage.getJwtToken();
    final serverUrl = await secureStorage.getServerUrl();

    final mergedHeaders = {
      "Authorization": "Bearer $jwtToken",
      if (headers != null) ...headers,
    };

    return HttpService.sendRequest(
        "$serverUrl$path", method, mergedHeaders, body);
  }

  static Future<void> savePasswordList(List<Password> pList) async {
    await getHiveBox();
    await Hive.deleteBoxFromDisk(boxName);
    final box = await getHiveBox();

    await box.addAll(pList);
  }

  static Future<List<Password>> loadLocalPasswordList() async {
    final box = await getHiveBox();
    final list = box.values.toList();

    return list;
  }

  static Future<Box<Password>> getHiveBox() async {
    final secureStorage = SecureStorage.instance;
    final encryptionKey = await secureStorage.getDerivedKey();
    final box = await Hive.openBox<Password>(boxName,
        encryptionCipher: HiveAesCipher(hex.decode(encryptionKey)),
        collection: databaseName);
    return box;
  }
}
