import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class LocalSessionStore {
  Future<String?> readUserId();
  Future<void> writeUserId(String userId);
  Future<void> clear();
}

final class SecureLocalSessionStore implements LocalSessionStore {
  const SecureLocalSessionStore();

  static const _storage = FlutterSecureStorage();
  static const _productionKey = 'lotus_erp.production.owner_session';
  static const _developmentKey = 'lotus_erp.development.owner_session';

  String get _key => kReleaseMode ? _productionKey : _developmentKey;

  @override
  Future<String?> readUserId() => _storage.read(key: _key);

  @override
  Future<void> writeUserId(String userId) =>
      _storage.write(key: _key, value: userId);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
