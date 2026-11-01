import 'package:flutter/foundation.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_profile_repository.dart';

enum SupplierProfileState { loading, loaded, error, deleting, deleted }

class SupplierProfileLogic extends ChangeNotifier {
  final SupplierProfileRepository _repo;
  final int supplierId;

  SupplierProfileLogic({
    required this.supplierId,
    SupplierProfileRepository? repo,
  }) : _repo = repo ?? SupplierProfileRepository() {
    _load();
  }

  SupplierProfileState _state = SupplierProfileState.loading;
  SupplierProfileModel? _profile;
  String? _error;
  int _activeTab = 0;

  SupplierProfileState get state => _state;
  SupplierProfileModel? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == SupplierProfileState.loading;
  int get activeTab => _activeTab;

  Future<void> _load() async {
    _state = SupplierProfileState.loading;
    _error = null;
    notifyListeners();

    final result = await _repo.fetchProfile(supplierId);
    if (result == null) {
      _error = 'Supplier profile not found';
      _state = SupplierProfileState.error;
    } else {
      _profile = result;
      _state = SupplierProfileState.loaded;
    }
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  Future<bool> deactivateSupplier() async {
    final current = _profile;
    if (current == null) return false;

    _state = SupplierProfileState.deleting;
    notifyListeners();

    final ok = await _repo.deactivateSupplier(current.id);
    _state = ok ? SupplierProfileState.deleted : SupplierProfileState.loaded;
    notifyListeners();
    return ok;
  }
}
