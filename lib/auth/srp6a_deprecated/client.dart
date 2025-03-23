import 'dart:typed_data';

import 'package:mpass/auth/srp6a_deprecated/routines.dart';

class SRPClientSession {
  final SRPRoutines routines;
  SRPClientSession(this.routines);

  Future<SRPClientSessionStep1> step1(String userId, String userPassword) async {
    if (userId.trim().isEmpty) {
      throw Exception("User identity must not be null nor empty");
    }
    if (userPassword.isEmpty) {
      throw Exception("User password must not be null");
    }
    final identityHash = await routines.computeIdentityHash(userId, userPassword);
    return SRPClientSessionStep1(routines, userId, identityHash);
  }
}

class SRPClientSessionStep1 {
  final SRPRoutines routines;
  final String I;
  final Uint8List identityHash;

  SRPClientSessionStep1(this.routines, this.I, this.identityHash);

  Future<SRPClientSessionStep2> step2(BigInt salt, BigInt B) async {
    if (salt == BigInt.zero) {
      throw Exception("Salt (s) must not be null");
    }
    if (B == BigInt.zero) {
      throw Exception("Public server value (B) must not be null");
    }
    final x = await routines.computeXStep2(salt, identityHash);
    final a = routines.generatePrivateValue();
    final A = routines.computeClientPublicValue(a);
    final k = await routines.computeK();
    final u = await routines.computeU(A, B);
    final S = routines.computeClientSessionKey(k, x, u, a, B);
    final m1 = await routines.computeClientEvidence(I, salt, A, B, S);
    return SRPClientSessionStep2(routines, A, m1, S);
  }

  Map<String, dynamic> toJSON() {
    return {
      'I': I,
      'identityHash': identityHash.toList(),
    };
  }

  static SRPClientSessionStep1 fromState(
      SRPRoutines routines, Map<String, dynamic> state) {
    return SRPClientSessionStep1(
      routines,
      state['I'],
      Uint8List.fromList(List<int>.from(state['identityHash'])),
    );
  }
}

class SRPClientSessionStep2 {
  final SRPRoutines routines;
  final BigInt A;
  final BigInt m1;
  final BigInt S;

  SRPClientSessionStep2(this.routines, this.A, this.m1, this.S);

  Future<void> step3(BigInt m2) async {
    if (m2 == BigInt.zero) {
      throw Exception("Server evidence (m2) must not be null");
    }
    final computedm2 = await routines.computeServerEvidence(A, m1, S);
    if (computedm2 != m2) {
      throw Exception("Bad server credentials");
    }
  }

  Map<String, String> toJSON() {
    return {
      'A': A.toRadixString(16),
      'm1': m1.toRadixString(16),
      'S': S.toRadixString(16),
    };
  }

  static SRPClientSessionStep2 fromState(
      SRPRoutines routines, Map<String, String> state) {
    return SRPClientSessionStep2(
      routines,
      BigInt.parse(state['A']!, radix: 16),
      BigInt.parse(state['m1']!, radix: 16),
      BigInt.parse(state['S']!, radix: 16),
    );
  }
}