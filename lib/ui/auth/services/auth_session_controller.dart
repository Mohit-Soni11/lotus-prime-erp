import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_result.dart';
import 'auth_service.dart';
import 'auth_session_gateway.dart';

enum AuthSessionStatus { checking, signedOut, authorized, unavailable }

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({AuthSessionGateway? gateway})
      : _gateway = gateway ?? AuthService();

  static final AuthSessionController instance = AuthSessionController();

  final AuthSessionGateway _gateway;
  StreamSubscription<String?>? _subscription;
  AuthSessionStatus _status = AuthSessionStatus.checking;
  String _message = '';
  int _generation = 0;
  bool _interactiveOperation = false;

  AuthSessionStatus get status => _status;
  String get message => _message;

  void start() {
    _subscription ??= _gateway.authUserIds().listen(
          _onAuthUserChanged,
          onError: (Object _) => _setStatus(
            AuthSessionStatus.unavailable,
            'Could not check your session. Check your connection and retry.',
          ),
        );
  }

  Future<void> _onAuthUserChanged(String? userId) async {
    final generation = ++_generation;
    if (_interactiveOperation) return;
    if (userId == null) {
      _setStatus(AuthSessionStatus.signedOut);
      return;
    }

    _setStatus(AuthSessionStatus.checking);
    final check = await _gateway.validateCurrentSession();
    if (generation != _generation ||
        _interactiveOperation ||
        _gateway.currentUserId != userId) {
      return;
    }
    switch (check.status) {
      case SessionCheckStatus.authorized:
        _setStatus(AuthSessionStatus.authorized);
      case SessionCheckStatus.unavailable:
        _setStatus(AuthSessionStatus.unavailable, check.message);
      case SessionCheckStatus.rejected:
      case SessionCheckStatus.verificationRequired:
        try {
          await _gateway.signOut();
          if (generation == _generation) {
            _setStatus(AuthSessionStatus.signedOut, check.message);
          }
        } catch (_) {
          _setStatus(
            AuthSessionStatus.unavailable,
            'Could not end the invalid session. Retry or restart the app.',
          );
        }
    }
  }

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    _interactiveOperation = true;
    ++_generation;
    try {
      final result = await _gateway.loginUser(email: email, password: password);
      final authorized = result.isSuccess && _gateway.currentUserId != null;
      _setStatus(authorized
          ? AuthSessionStatus.authorized
          : AuthSessionStatus.signedOut);
      if (result.isSuccess && !authorized) {
        return const AuthResult(
          AuthResultCode.failure,
          'Sign in could not be completed. Please try again.',
        );
      }
      return result;
    } catch (_) {
      _setStatus(
        AuthSessionStatus.unavailable,
        'Sign in could not be completed. Please retry.',
      );
      return const AuthResult(
        AuthResultCode.failure,
        'Sign in could not be completed. Please retry.',
      );
    } finally {
      _interactiveOperation = false;
    }
  }

  Future<AuthResult> registerOwner({
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
  }) async {
    _interactiveOperation = true;
    ++_generation;
    try {
      return await _gateway.registerOwner(
        email: email,
        password: password,
        ownerName: ownerName,
        mobile: mobile,
      );
    } catch (_) {
      return const AuthResult(
        AuthResultCode.failure,
        'Account could not be created. Please try again.',
      );
    } finally {
      try {
        if (_gateway.currentUserId != null) {
          await _gateway.signOut();
        }
        _setStatus(AuthSessionStatus.signedOut);
      } catch (_) {
        _setStatus(
          AuthSessionStatus.unavailable,
          'Could not complete sign-out after account creation.',
        );
      } finally {
        _interactiveOperation = false;
      }
    }
  }

  Future<void> retry() => _onAuthUserChanged(_gateway.currentUserId);

  Future<void> signOut() async {
    _interactiveOperation = true;
    ++_generation;
    try {
      await _gateway.signOut();
      _setStatus(AuthSessionStatus.signedOut);
    } catch (_) {
      _setStatus(
        AuthSessionStatus.unavailable,
        'Could not sign out. Check your connection and retry.',
      );
    } finally {
      _interactiveOperation = false;
    }
  }

  void _setStatus(AuthSessionStatus status, [String message = '']) {
    if (_status == status && _message == message) return;
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
