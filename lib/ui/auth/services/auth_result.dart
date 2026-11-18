enum AuthResultCode {
  success,
  verificationRequired,
  verificationDeliveryFailed,
  failure,
}

class AuthResult {
  const AuthResult(this.code, this.message);

  final AuthResultCode code;
  final String message;

  bool get isSuccess => code == AuthResultCode.success;
  bool get accountCreated =>
      code == AuthResultCode.success ||
      code == AuthResultCode.verificationDeliveryFailed;
}

enum SessionCheckStatus {
  authorized,
  verificationRequired,
  rejected,
  unavailable,
}

class SessionCheck {
  const SessionCheck(this.status, this.message);

  final SessionCheckStatus status;
  final String message;

  bool get isAuthorized => status == SessionCheckStatus.authorized;
}
