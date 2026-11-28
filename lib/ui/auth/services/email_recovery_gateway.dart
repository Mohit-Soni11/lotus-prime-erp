class VerifiedEmailIdentity {
  const VerifiedEmailIdentity({required this.email, required this.uid});

  final String email;
  final String uid;
}

abstract interface class EmailRecoveryGateway {
  bool get isConfigured;

  Future<void> sendSignInLink(String email);

  Future<VerifiedEmailIdentity> verifySignInLink(String email, String link);
}

class EmailRecoveryException implements Exception {
  const EmailRecoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
