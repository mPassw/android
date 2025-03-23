import 'package:mpass/auth/srp6a_deprecated/routines.dart';

Future<BigInt> createVerifier(
    SRPRoutines routines, String I, BigInt s, String P) async {
  if (I.trim().isEmpty) throw Exception("Identity (I) must not be null or empty.");
  if (s == BigInt.zero) throw Exception("Salt (s) must not be null.");
  if (P.isEmpty) throw Exception("Password (P) must not be null");
  final x = await routines.computeX(I, s, P);
  return routines.computeVerifier(x);
}

class IVerifierAndSalt {
  final BigInt v;
  final BigInt s;
  IVerifierAndSalt(this.v, this.s);
}

Future<IVerifierAndSalt> createVerifierAndSalt(
    SRPRoutines routines, String I, String P,
    [int? sBytes]) async {
  final s = await routines.generateRandomSalt(sBytes);
  final v = await createVerifier(routines, I, s, P);
  return IVerifierAndSalt(v, s);
}