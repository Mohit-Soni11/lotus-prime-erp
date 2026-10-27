// -----------------------------------------------------------------------------
// FILE: customer_profile_logic.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum ProfileState { loading, loaded, error, deleting, deleted, saving }

class CustomerProfileLogic extends ChangeNotifier {
  final CustomerProfileRepository _repo;
  final int customerId;

  // Optional callback used when an advance order is converted to a sale.
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  CustomerProfileLogic({
    required this.customerId,
    CustomerProfileRepository? repo,
    this.onConvertAdvanceToSale,
  }) : _repo = repo ?? CustomerProfileRepository() {
    _load();
  }

  // State
  ProfileState _state = ProfileState.loading;
  CustomerProfileModel? _profile;
  String? _error;
  int _loadRequestId = 0;
  bool _isDisposed = false;

  String? _deleteError;

  // Getters
  ProfileState get state => _state;
  CustomerProfileModel? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == ProfileState.loading;
  String? get deleteError => _deleteError;

  // Load
  Future<void> _load() async {
    final requestId = ++_loadRequestId;
    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.fetchProfile(customerId);
      if (_isDisposed || requestId != _loadRequestId) return;
      if (result != null) {
        _profile = result;
        _state = ProfileState.loaded;
      } else {
        _error = 'Customer not found';
        _state = ProfileState.error;
      }
    } catch (error, stackTrace) {
      if (_isDisposed || requestId != _loadRequestId) return;
      AppLogger.error(
        'Customer profile load failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _error = 'Failed to load customer profile. Please try again.';
      _state = ProfileState.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => _load();

  Future<CustomerBillDetailModel?> fetchBillDetails(int billId) {
    return _repo.fetchBillDetails(customerId: customerId, billId: billId);
  }

  Future<GirviInvoiceDraft?> fetchGirviInvoiceDraft(int loanId) {
    return _repo.fetchGirviInvoiceDraft(
      customerId: customerId,
      loanId: loanId,
    );
  }

  // Convert advance to new sale
  void triggerConvertAdvanceToSale(int advanceOrderId) {
    onConvertAdvanceToSale?.call(advanceOrderId, customerId);
  }

  // Delete
  Future<bool> deleteCustomer() async {
    _state = ProfileState.deleting;
    _deleteError = null;
    notifyListeners();

    final result = await _repo.deleteCustomer(customerId);
    if (_isDisposed) return false;
    if (result.deleted) {
      _state = ProfileState.deleted;
    } else {
      _deleteError = result.message;
      _state = ProfileState.loaded;
    }
    notifyListeners();
    return result.deleted;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadRequestId++;
    super.dispose();
  }
}
