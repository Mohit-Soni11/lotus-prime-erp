import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/auth/services/auth_result.dart';
import 'package:lotus_erp/ui/auth/services/auth_session_controller.dart';
import 'package:lotus_erp/ui/auth/services/auth_session_gateway.dart';

class _FakeGateway implements AuthSessionGateway {
  final events = StreamController<String?>.broadcast(sync: true);
  String? userId;
  SessionCheck nextCheck =
      const SessionCheck(SessionCheckStatus.authorized, '');
  AuthResult nextLogin = const AuthResult(AuthResultCode.success, 'Signed in.');
  Completer<AuthResult>? pendingRegistration;
  int signOutCount = 0;

  @override
  Stream<String?> authUserIds() => events.stream;

  @override
  String? get currentUserId => userId;

  void emit(String? id) {
    userId = id;
    events.add(id);
  }

  @override
  Future<SessionCheck> validateCurrentSession() async => nextCheck;

  @override
  Future<AuthResult> loginUser({
    required String username,
    required String password,
  }) async {
    if (nextLogin.isSuccess) emit('owner-1');
    return nextLogin;
  }

  @override
  Future<AuthResult> registerOwner({
    required String username,
    required String password,
    required String ownerName,
    required String mobile,
  }) async {
    emit('new-owner');
    if (pendingRegistration case final pending?) {
      return pending.future;
    }
    return const AuthResult(AuthResultCode.success, 'Created.');
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    emit(null);
  }

  Future<void> dispose() => events.close();
}

void main() {
  late _FakeGateway gateway;
  late AuthSessionController session;

  setUp(() {
    gateway = _FakeGateway();
    session = AuthSessionController(gateway: gateway)..start();
  });

  tearDown(() async {
    session.dispose();
    await gateway.dispose();
  });

  test('restored session reaches dashboard only after validation', () async {
    gateway.emit('owner-1');
    expect(session.status, AuthSessionStatus.checking);
    await Future<void>.delayed(Duration.zero);
    expect(session.status, AuthSessionStatus.authorized);
  });

  test('inactive restored account is signed out', () async {
    gateway.nextCheck = const SessionCheck(
      SessionCheckStatus.rejected,
      'Account inactive.',
    );
    gateway.emit('owner-1');
    await Future<void>.delayed(Duration.zero);
    expect(session.status, AuthSessionStatus.signedOut);
    expect(gateway.signOutCount, 1);
  });

  test('temporary validation failure stays locked and can retry', () async {
    gateway.nextCheck = const SessionCheck(
      SessionCheckStatus.unavailable,
      'Connection unavailable.',
    );
    gateway.emit('owner-1');
    await Future<void>.delayed(Duration.zero);
    expect(session.status, AuthSessionStatus.unavailable);
    expect(gateway.signOutCount, 0);

    gateway.nextCheck = const SessionCheck(SessionCheckStatus.authorized, '');
    await session.retry();
    expect(session.status, AuthSessionStatus.authorized);
  });

  test('account creation cannot open the protected workspace', () async {
    gateway.pendingRegistration = Completer<AuthResult>();
    final registration = session.registerOwner(
      username: 'owner',
      password: 'password123',
      ownerName: 'Owner',
      mobile: '9999999999',
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.status, isNot(AuthSessionStatus.authorized));

    gateway.pendingRegistration!.complete(
      const AuthResult(AuthResultCode.success, 'Created.'),
    );
    expect((await registration).accountCreated, isTrue);
    expect(session.status, AuthSessionStatus.signedOut);
  });

  test('validated sign-in opens workspace', () async {
    gateway.emit(null);
    final result = await session.loginUser(
      username: 'owner',
      password: 'password123',
    );
    expect(result.isSuccess, isTrue);
    expect(session.status, AuthSessionStatus.authorized);
  });
}
