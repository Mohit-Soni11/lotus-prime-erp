enum AuthResultCode {
  success,
  failure,
}

class AuthResult {
  const AuthResult(this.code, this.message, {this.recoveryCode});

  final AuthResultCode code;
  final String message;
  final String? recoveryCode;

  bool get isSuccess => code == AuthResultCode.success;
  bool get accountCreated => code == AuthResultCode.success;
}

enum SessionCheckStatus {
  authorized,
  rejected,
  unavailable,
}

class SessionCheck {
  const SessionCheck(this.status, this.message);

  final SessionCheckStatus status;
  final String message;

  bool get isAuthorized => status == SessionCheckStatus.authorized;
}
