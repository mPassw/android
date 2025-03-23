import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

typedef HashFunction = Future<Uint8List> Function(Uint8List data);

class CrossEnvCrypto {
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static Future<Uint8List> hashSHA1(Uint8List data) async {
    return Uint8List.fromList(crypto.sha1.convert(data).bytes);
  }

  static Future<Uint8List> hashSHA256(Uint8List data) async {
    return Uint8List.fromList(crypto.sha256.convert(data).bytes);
  }

  static Future<Uint8List> hashSHA384(Uint8List data) async {
    return Uint8List.fromList(crypto.sha384.convert(data).bytes);
  }

  static Future<Uint8List> hashSHA512(Uint8List data) async {
    return Uint8List.fromList(crypto.sha512.convert(data).bytes);
  }
}

class CompatibleCrypto {
  static final Map<String, HashFunction> hashFunctions = {
    'SHA1': CrossEnvCrypto.hashSHA1,
    'SHA256': CrossEnvCrypto.hashSHA256,
    'SHA384': CrossEnvCrypto.hashSHA384,
    'SHA512': CrossEnvCrypto.hashSHA512,
  };

  static Uint8List randomBytes(int length) => CrossEnvCrypto.randomBytes(length);
}