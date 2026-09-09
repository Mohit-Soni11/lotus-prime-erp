part of 'booking_advance_controller.dart';

extension BookingAdvanceControllerCustomerOperations
    on BookingAdvanceController {
  void _searchCustomer(String query) {
    _searchTimer?.cancel();
    if (query.trim().length < 2) {
      customerResults = [];
      customerNotFound = false;
      _emitChanged();
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      isSearching = true;
      _emitChanged();
      try {
        customerResults = await _repo.searchCustomers(query);
        customerNotFound = customerResults.isEmpty;
      } catch (_) {
        customerResults = [];
        customerNotFound = false;
      }
      isSearching = false;
      _emitChanged();
    });
  }

  void _handleCustomerLookupInput(String query) {
    if (selectedCustomerId != null && !_selectedCustomerMatchesCurrentInput()) {
      selectedCustomerId = null;
      _selectedCustomerMobile = '';
      _selectedCustomerName = '';
    }
    _searchCustomer(query);
  }

  void _clearCustomerDetails() {
    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    selectedCustomerId = null;
    _selectedCustomerMobile = '';
    _selectedCustomerName = '';
    customerResults = [];
    customerNotFound = false;
    _emitChanged();
  }

  void _selectCustomerFromSearch(Map<String, dynamic> c) {
    selectedCustomerId = c['id'];
    mobileCtrl.text = c['mobile'] ?? '';
    nameCtrl.text = c['name'] ?? '';
    cityCtrl.text = c['address'] ?? c['city'] ?? '';
    _selectedCustomerMobile = mobileCtrl.text.trim();
    _selectedCustomerName = nameCtrl.text.trim();
    customerResults = [];
    customerNotFound = false;
    _emitChanged();
  }

  bool _selectedCustomerMatchesCurrentInput() {
    return mobileCtrl.text.trim() == _selectedCustomerMobile &&
        nameCtrl.text.trim() == _selectedCustomerName;
  }
}
