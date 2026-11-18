import 'auth_result.dart';

abstract interface class AuthSessionGateway {
  Stream<String?> authUserIds();

  String? get currentUserId;

  Future<SessionCheck> validateCurrentSession();

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  });

  Future<AuthResult> registerOwner({
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
  });

  Future<void> signOut();
}
