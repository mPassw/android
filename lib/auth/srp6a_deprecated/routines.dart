import 'dart:math';
import 'dart:typed_data';
import 'package:mpass/auth/srp6a_deprecated/parameters.dart';
import 'package:mpass/auth/srp6a_deprecated/srp_utils.dart';

class SRPRoutines {
  final SRPParameters parameters;

  SRPRoutines(this.parameters);

  Future<Uint8List> hash(List<Uint8List> arrays) async {
    // Concatenate all byte arrays.
    int length = arrays.fold(0, (prev, element) => prev + element.length);
    final target = Uint8List(length);
    int offset = 0;
    for (final arr in arrays) {
      target.setRange(offset, offset + arr.length, arr);
      offset += arr.length;
    }
    return await parameters.H(target);
  }

  Future<Uint8List> hashPadded(int targetLen, List<Uint8List> arrays) async {
    final paddedArrays =
        arrays.map((arr) => padStartArrayBuffer(arr, targetLen)).toList();
    return await hash(paddedArrays);
  }

  Future<BigInt> computeK() async {
    final targetLength = ((parameters.nBits + 7) ~/ 8);
    final padded = await hashPadded(targetLength, [
      bigIntToArrayBuffer(parameters.primeGroup.N),
      bigIntToArrayBuffer(parameters.primeGroup.g),
    ]);
    return arrayBufferToBigInt(padded);
  }

  Future<BigInt> generateRandomSalt([int? numBytes]) async {
    final hBits = await hashBitCount(parameters);
    // Recommended salt bytes is > than hash output bytes.
    final saltBytes = numBytes ?? ((2 * hBits) ~/ 8);
    return generateRandomBigInt(saltBytes);
  }

  Future<BigInt> computeX(String I, BigInt s, String P) async {
    final identityHash = await computeIdentityHash(I, P);
    final sBytes = bigIntToArrayBuffer(s);
    final hashResult = await hash([sBytes, identityHash]);
    return arrayBufferToBigInt(hashResult);
  }

  Future<BigInt> computeXStep2(BigInt s, Uint8List identityHash) async {
    final sBytes = bigIntToArrayBuffer(s);
    final hashResult = await hash([sBytes, identityHash]);
    return arrayBufferToBigInt(hashResult);
  }

  Future<Uint8List> computeIdentityHash(String I, String P) async {
    return await hash([stringToArrayBuffer(P)]);
  }

  BigInt computeVerifier(BigInt x) {
    return modPow(parameters.primeGroup.g, x, parameters.primeGroup.N);
  }

  Future<BigInt> createVerifier(String I, BigInt salt, String P) async {
    BigInt x = await computeX(I, salt, P);
    // Compute verifier v = g^x mod N
    return computeVerifier(x);
  }

  BigInt generatePrivateValue() {
    final numBits = max(256, parameters.nBits);
    BigInt bi;
    do {
      bi = generateRandomBigInt((numBits / 8).ceil()) % parameters.primeGroup.N;
    } while (bi == BigInt.zero);
    return bi;
  }

  BigInt computeClientPublicValue(BigInt a) {
    return modPow(parameters.primeGroup.g, a, parameters.primeGroup.N);
  }

  bool isValidPublicValue(BigInt value) {
    return value % parameters.primeGroup.N != BigInt.zero;
  }

  Future<BigInt> computeU(BigInt A, BigInt B) async {
    final targetLength = ((parameters.nBits + 7) ~/ 8);
    final hashResult = await hashPadded(
        targetLength, [bigIntToArrayBuffer(A), bigIntToArrayBuffer(B)]);
    return arrayBufferToBigInt(hashResult);
  }

  Future<BigInt> computeClientEvidence(
      String I, BigInt s, BigInt A, BigInt B, BigInt S) async {
    final hashResult = await hash([
      bigIntToArrayBuffer(A),
      bigIntToArrayBuffer(B),
      bigIntToArrayBuffer(S),
    ]);
    return arrayBufferToBigInt(hashResult);
  }

  Future<BigInt> computeServerEvidence(BigInt A, BigInt m1, BigInt S) async {
    final hashResult = await hash([
      bigIntToArrayBuffer(A),
      bigIntToArrayBuffer(m1),
      bigIntToArrayBuffer(S),
    ]);
    return arrayBufferToBigInt(hashResult);
  }

  BigInt computeClientSessionKey(
      BigInt k, BigInt x, BigInt u, BigInt a, BigInt B) {
    final N = parameters.primeGroup.N;
    final exp = u * x + a;
    final tmp = (modPow(parameters.primeGroup.g, x, N) * k) % N;
    return modPow(B + N - tmp, exp, N);
  }
}
