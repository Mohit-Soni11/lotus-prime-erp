import 'package:flutter/foundation.dart';
import 'package:lotus_erp/core/events/shop_identity_updates.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/data/shop_identity_repository.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/domain/shop_identity.dart';

class ShopIdentityController extends ChangeNotifier {
  ShopIdentityController(
    this._reader, {
    ShopIdentityUpdates? updates,
  }) : _updates = updates ?? ShopIdentityUpdates.instance {
    _updates.revision.addListener(_reloadFromCommittedChange);
    load();
  }

  final ShopIdentityReader _reader;
  final ShopIdentityUpdates _updates;

  ShopIdentity _identity = const ShopIdentity.notConfigured();
  String? _errorMessage;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isExpanded = false;
  bool _isDisposed = false;
  int _requestVersion = 0;

  ShopIdentity get identity => _identity;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isExpanded => _isExpanded;

  Future<void> load() async {
    final requestVersion = ++_requestVersion;
    final isFirstRequest = _isInitialLoading;
    if (!isFirstRequest) {
      _isRefreshing = true;
    }
    _errorMessage = null;
    _notifyIfActive();

    try {
      final identity = await _reader.load();
      if (!_isActiveRequest(requestVersion)) return;
      _identity = identity;
    } catch (error, stackTrace) {
      AppLogger.error('Unable to load shop identity: $error');
      AppLogger.debug(stackTrace.toString());
      if (!_isActiveRequest(requestVersion)) return;
      _errorMessage = 'Unable to load the shop profile.';
    } finally {
      if (_isActiveRequest(requestVersion)) {
        _isInitialLoading = false;
        _isRefreshing = false;
        _notifyIfActive();
      }
    }
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    _notifyIfActive();
  }

  void _reloadFromCommittedChange() {
    load();
  }

  bool _isActiveRequest(int requestVersion) =>
      !_isDisposed && requestVersion == _requestVersion;

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _updates.revision.removeListener(_reloadFromCommittedChange);
    super.dispose();
  }
}
