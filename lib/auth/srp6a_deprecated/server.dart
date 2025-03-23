import 'package:mpass/auth/srp6a_deprecated/parameters.dart';
import 'package:mpass/auth/srp6a_deprecated/routines.dart';
import 'package:mpass/auth/srp6a_deprecated/srp_utils.dart';

class SRPServerSession {
  final SRPRoutines routines;
  SRPServerSession(this.routines);

  Future<SRPServerSessionStep1> step1(
      String identifier, BigInt salt, BigInt verifier) async {
    final b = routines.generatePrivateValue();
    final k = await routines.computeK();
    final B = computeServerPublicValue(routines.parameters, k, verifier, b);
    return SRPServerSessionStep1(routines, identifier, salt, verifier, b, B);
  }
}

class SRPServerSessionStep1 {
  final SRPRoutines routines;
  final String identifier;
  final BigInt salt;
  final BigInt verifier;
  final BigInt b;
  final BigInt B;

  SRPServerSessionStep1(
      this.routines, this.identifier, this.salt, this.verifier, this.b, this.B);

  Future<BigInt> sessionKey(BigInt A) async {
    if (A == BigInt.zero) {
      throw Exception("Client public value (A) must not be null");
    }
    if (!routines.isValidPublicValue(A)) {
      throw Exception(
          "Invalid Client public value (A): ${A.toRadixString(16)}");
    }
    final u = await routines.computeU(A, B);
    final S = computeServerSessionKey(
        routines.parameters.primeGroup.N, verifier, u, A, b);
    return S;
  }

  Future<BigInt> step2(BigInt A, BigInt m1) async {
    if (m1 == BigInt.zero) {
      throw Exception("Client evidence (m1) must not be null");
    }
    final S = await sessionKey(A);
    final computedm1 =
        await routines.computeClientEvidence(identifier, salt, A, B, S);
    if (computedm1 != m1) {
      throw Exception("Bad client credentials");
    }
    final m2 = await routines.computeServerEvidence(A, m1, S);
    return m2;
  }

  Map<String, String> toJSON() {
    return {
      'identifier': identifier,
      'salt': salt.toRadixString(16),
      'verifier': verifier.toRadixString(16),
      'b': b.toRadixString(16),
      'B': B.toRadixString(16),
    };
  }

  static SRPServerSessionStep1 fromState(
      SRPRoutines routines, Map<String, String> state) {
    return SRPServerSessionStep1(
      routines,
      state['identifier']!,
      BigInt.parse(state['salt']!, radix: 16),
      BigInt.parse(state['verifier']!, radix: 16),
      BigInt.parse(state['b']!, radix: 16),
      BigInt.parse(state['B']!, radix: 16),
    );
  }
}

BigInt computeServerPublicValue(
    SRPParameters parameters, BigInt k, BigInt v, BigInt b) {
  final N = parameters.primeGroup.N;
  return (modPow(parameters.primeGroup.g, b, N) + v * k) % N;
}

BigInt computeServerSessionKey(
    BigInt N, BigInt v, BigInt u, BigInt A, BigInt b) {
  return modPow(((modPow(v, u, N) * A) % N), b, N);
}
