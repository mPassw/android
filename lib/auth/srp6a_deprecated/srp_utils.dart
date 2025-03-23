import 'dart:convert';
import 'dart:typed_data';

import 'package:mpass/auth/srp6a_deprecated/crypto_helpers.dart';
import 'package:mpass/auth/srp6a_deprecated/parameters.dart';

Uint8List bigIntToArrayBuffer(BigInt n) {
  String hex = n.toRadixString(16);
  if (hex.length % 2 != 0) {
    hex = "0$hex";
  }
  final length = hex.length ~/ 2;
  final result = Uint8List(length);
  for (int i = 0; i < length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

BigInt arrayBufferToBigInt(Uint8List bytes) {
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return BigInt.parse(hex, radix: 16);
}

Uint8List stringToArrayBuffer(String str) {
  return Uint8List.fromList(utf8.encode(str));
}

Uint8List padStartArrayBuffer(Uint8List arrayBuffer, int targetLength) {
  if (arrayBuffer.length < targetLength) {
    final result = Uint8List(targetLength);
    // The beginning bytes remain zero.
    result.setRange(
        targetLength - arrayBuffer.length, targetLength, arrayBuffer);
    return result;
  }
  return arrayBuffer;
}

Future<int> hashBitCount(SRPParameters parameters) async {
  final oneBytes = bigIntToArrayBuffer(BigInt.one);
  final hashResult = await parameters.H(oneBytes);
  return hashResult.length * 8;
}

BigInt modPow(BigInt base, BigInt exponent, BigInt mod) {
  if (base < BigInt.zero) throw Exception("Invalid base: $base");
  if (exponent < BigInt.zero) throw Exception("Invalid exponent: $exponent");
  if (mod < BigInt.one) throw Exception("Invalid modulo: $mod");
  BigInt result = BigInt.one;
  BigInt b = base % mod;
  BigInt exp = exponent;
  while (exp > BigInt.zero) {
    if (exp.isOdd) {
      result = (result * b) % mod;
    }
    exp = exp >> 1;
    b = (b * b) % mod;
  }
  return result;
}

BigInt generateRandomBigInt(int numBytes) {
  final bytes = CompatibleCrypto.randomBytes(numBytes);
  return arrayBufferToBigInt(bytes);
}

String generateRandomString([int characterCount = 10]) {
  final byteCount = (characterCount + 1) ~/ 2;
  final bytes = CompatibleCrypto.randomBytes(byteCount);
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return hex.substring(0, characterCount);
}
