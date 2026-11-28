import 'package:lotus_erp/ui/auth/services/auth_service.dart';

import '../data/google_drive_auth.dart';

abstract interface class GoogleRecoveryLinker {
  Future<void> verifyPassword(String password);
  Future<void> link(VerifiedGoogleIdentity identity, String password);
  Future<void> unlink();
  Future<bool> isLinked(String? googleSubject);
}

class LocalGoogleRecoveryLinker implements GoogleRecoveryLinker {
  const LocalGoogleRecoveryLinker(this.auth);

  final AuthService auth;

  @override
  Future<void> verifyPassword(String password) async {
    final result = await auth.verifyRecoverySetupPassword(password);
    if (!result.isSuccess) throw StateError(result.message);
  }

  @override
  Future<void> link(VerifiedGoogleIdentity identity, String password) async {
    final result = await auth.linkRecoveryToGoogleAccount(
      currentPassword: password,
      email: identity.email,
      googleSubject: identity.subject,
    );
    if (!result.isSuccess) throw StateError(result.message);
  }

  @override
  Future<void> unlink() => auth.unlinkGoogleRecovery();

  @override
  Future<bool> isLinked(String? googleSubject) => googleSubject == null
      ? Future.value(false)
      : auth.isRecoveryLinkedToGoogle(subject: googleSubject);
}
