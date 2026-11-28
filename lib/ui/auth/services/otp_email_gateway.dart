abstract interface class OtpEmailGateway {
  Future<void> send(
      {required String email,
      required String googleSubject,
      required String code});
}

class OtpEmailException implements Exception {
  const OtpEmailException(this.message);
  final String message;
}
