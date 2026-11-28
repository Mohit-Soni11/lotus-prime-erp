import 'auth_result.dart';

abstract interface class AuthSessionGateway {
  Stream<String?> authUserIds();

  String? get currentUserId;

  Future<SessionCheck> validateCurrentSession();

  Future<AuthResult> loginUser({
    required String username,
    required String password,
  });

  Future<AuthResult> registerOwner({
    required String username,
    required String password,
    required String ownerName,
    required String mobile,
    String? companyName,
  });

  Future<void> signOut();
}
