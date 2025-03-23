import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;
import 'package:flutter/material.dart';
import 'package:mpass/auth/login_page.dart';
import 'package:mpass/auth/server_url_page.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/srp/srp6_client.dart';
import 'package:pointycastle/srp/srp6_verifier_generator.dart';
import 'package:pointycastle/srp/srp6_standard_groups.dart';

class AuthorizationService {
  static const hashFunction = "SHA512";

  static const validateServerKey = "x-mpass-version";

  static const authStep1Path = "/auth/step1";
  static const authStep2Path = "/auth/step2";

  static const registrationPath = "/users";

  static BigInt N = BigInt.parse(
      "AC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC319294"
      "3DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310D"
      "CD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FB"
      "D5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF74"
      "7359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A"
      "436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D"
      "5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E73"
      "03CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB6"
      "94B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F"
      "9E4AFF73",
      radix: 16);
  static BigInt g = BigInt.two;

  static Future<void> login(String identifier, String password) async {
    final secureStorage = SecureStorage.instance;
    SRP6Client client = SRP6Client(
        group: SRP6GroupParameters(N: N, g: g),
        digest: SHA512Digest(),
        random: secureRandom());

    final step1Response = await HttpService.sendRequest(
        '${await secureStorage.getServerUrl()}$authStep1Path',
        'POST',
        Map.of({"Content-Type": "application/json"}),
        Map.of({"identifier": identifier}));

    final body = jsonDecode(step1Response.body);
    final String authId = body['authId'];
    final String salt = body['salt'];
    final email = body['email'];
    final String B = body['b'];

    Uint8List saltBytes = Uint8List.fromList(hex.decode(salt));
    Uint8List emailBytes = Uint8List.fromList(utf8.encode(email));
    Uint8List passwordBytes = Uint8List.fromList(utf8.encode(password));
    BigInt bBigInt = BigInt.parse(B, radix: 16);

    client.generateClientCredentials(saltBytes, emailBytes, passwordBytes);
    client.calculateSecret(bBigInt);
    client.calculateClientEvidenceMessage();

    String ahex = client.A!.toRadixString(16);
    String m1hex = client.M1!.toRadixString(16);

    final step2Response = await HttpService.sendRequest(
        '${await secureStorage.getServerUrl()}$authStep2Path',
        'POST',
        Map.of({"Content-Type": "application/json"}),
        Map.of({"authId": authId, "a": ahex, "m1": m1hex, "expiresIn": "2h"}));

    final step2ResponseBody = jsonDecode(step2Response.body);
    final String token = step2ResponseBody['token'];
    final String hexM2 = step2ResponseBody['m2'];
    BigInt m2BigInt = BigInt.parse(hexM2, radix: 16);

    client.verifyServerEvidenceMessage(m2BigInt);

    secureStorage.setJwtToken(token);

    String hexSecretKey = await calculateEncryptionKey(password, salt);

    await secureStorage.setDerivedKey(hexSecretKey);
    await secureStorage.setSalt(salt);
    await secureStorage.setMasterPassword(password);
    await secureStorage.setEmail(email);
  }

  static Future<void> register(
      String email, String password, String username) async {
    SecureStorage secureStorage = SecureStorage.instance;

    final Map<String, String> verifierAndSalt =
        await generateVerifierAndSalt(email, password);

    final String? hexVerifier = verifierAndSalt["verifier"];
    final String? hexSalt = verifierAndSalt["salt"];

    await HttpService.sendRequest(
        "${await secureStorage.getServerUrl()}$registrationPath",
        "POST",
        Map.of({"Content-Type": "application/json"}),
        Map.of({
          "email": email,
          "username": username.isEmpty ? null : username,
          "salt": hexSalt,
          "verifier": hexVerifier
        }));
  }

  static Future<Map<String, String>> generateVerifierAndSalt(
      String email, String password) async {
    SRP6VerifierGenerator generator = SRP6VerifierGenerator(
        group: SRP6GroupParameters(N: N, g: g), digest: SHA512Digest());

    Uint8List emailBytes = Uint8List.fromList(utf8.encode(email));
    Uint8List passwordBytes = Uint8List.fromList(utf8.encode(password));

    Uint8List salt = generateSalt();
    BigInt verifier =
        generator.generateVerifier(salt, emailBytes, passwordBytes);
    String hexSalt = uint8ListToHex(salt);
    String hexVerifier = verifier.toRadixString(16);
    return {"verifier": hexVerifier, "salt": hexSalt};
  }

  static Future<void> validateServer(String text) async {
    String url = text.trim();
    final secureStorage = SecureStorage.instance;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final fullUrl =
        RegExp(r'^(http|https)://').hasMatch(url) ? url : "https://$url";

    final response = await HttpService.sendRequest(fullUrl, "GET", null, null);

    if (response.statusCode == 200 &&
        response.headers.containsKey(validateServerKey)) {
      await secureStorage.setServerUrl(fullUrl);
    } else {
      throw CustomException("Invalid URL");
    }
  }

  static Future<bool> validatePassword(String password) async {
    if (password.isEmpty) {
      return false;
    }
    final secureStorage = SecureStorage.instance;
    final salt = await secureStorage.getSalt();
    final derivedKey = await secureStorage.getDerivedKey();
    final encryptionKey = await calculateEncryptionKey(password, salt);
    return encryptionKey == derivedKey;
  }

  static Future<String> calculateEncryptionKey(
      String password, String salt) async {
    cryptography.Argon2id argon2id = cryptography.Argon2id(
        parallelism: 1, memory: 19456, iterations: 2, hashLength: 32);
    cryptography.SecretKey secretKey = await argon2id.deriveKeyFromPassword(
        password: password, nonce: hex.decode(salt));
    return hex.encode(await secretKey.extractBytes());
  }

  static Future<void> isJwtTokenValid() async {
    final secureStorage = SecureStorage.instance;
    final String jwtToken = await secureStorage.getJwtToken();

    final decodedJwtToken = jwt.JWT.decode(jwtToken);
    final payload = decodedJwtToken.payload;

    if (payload is Map<String, dynamic> &&
        payload.containsKey('exp') &&
        payload['exp'] is int) {
      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      if (expiryDate.isBefore(DateTime.now())) {
        await secureStorage.removeJwtToken();
        throw UnauthorizedException('Session expired');
      }
    } else {
      await secureStorage.removeJwtToken();
      throw UnauthorizedException('Session expired');
    }
  }

  static Future<void> logout(BuildContext context,
      [String message = "Logged out"]) async {
    final secureStorage = SecureStorage.instance;
    await secureStorage.removeJwtToken();
    if (!context.mounted) return;
    LoadingDialog.show(context);
    ScaffoldMessenger.of(context).showSnackBar(Sonner(message: message));
    LoadingDialog.hide(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ServerUrlPage()),
      (route) => false,
    );
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }

  static FortunaRandom secureRandom() {
    final secureRandom = FortunaRandom();

    final seed = Uint8List(32);
    final random = Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }

    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  static Uint8List generateSalt() {
    final random = secureRandom();
    return random.nextBytes(16);
  }

  static String uint8ListToHex(Uint8List data) {
    return data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }
}
