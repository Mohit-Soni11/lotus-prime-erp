// =============================================================================
// FILE        : booking_advance_controller.dart
// MODULE      : Sales / Booking & Advance
// LAYER       : Application Controller
// DESCRIPTION : Coordinates booking entry state, validation, and persistence.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../database/db/app_database.dart';
import '../../models/booking_advance/booking_advance/booking_advance_model.dart';
import '../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../../repositories/booking_advance/booking_advance_repository.dart';
import '../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'booking_rate_preference_policy.dart';

part 'booking_advance_controller_entry_operations.dart';
part 'booking_advance_controller_customer_operations.dart';
part 'booking_advance_controller_persistence.dart';

enum BookingType { open, locked }

class BookingInvoiceDraftResult {
  const BookingInvoiceDraftResult({
    required this.success,
    required this.message,
    required this.bookings,
  });

  final bool success;
  final String message;
  final List<EditableBookingAdvance> bookings;
}

class BookingAdvanceController extends ChangeNotifier {
  final BookingAdvanceRepository _repo;
  final BookingRatePreferencePolicy _ratePreferencePolicy =
      const BookingRatePreferencePolicy();

  BookingAdvanceController({BookingAdvanceRepository? repo})
      : _repo = repo ?? BookingAdvanceRepository() {
    cashCtrl.addListener(() {
      _cashInput = _p(cashCtrl.text);
      _syncSmartRatePreference();
      notifyListeners();
    });
    upiCtrl.addListener(() {
      _upiInput = _p(upiCtrl.text);
      _syncSmartRatePreference();
      notifyListeners();
    });
    cardCtrl.addListener(() {
      _cardInput = _p(cardCtrl.text);
      _syncSmartRatePreference();
      notifyListeners();
    });
    lockedRateCtrl.addListener(notifyListeners);

    _initBookingNumber();
  }

  String _shopDocumentCode = 'SH';
  String _currentYearToken = '';
  int _nextSequence = 0;
  bool _isNumberLoading = true;
  BookingAdvanceBillingModel _billingSettings =
      BookingAdvanceBillingModel.defaults();

  bool get isNumberLoading => _isNumberLoading;
  String get currentFinancialYear => _currentYearToken;
  int get nextSequence => _nextSequence;
  BookingAdvanceBillingModel get billingSettings => _billingSettings;
  int? editingOrderId;
  String? _editingOrderNo;
  bool isLoadingEditOrder = false;
  String? editLoadError;
  bool get isEditMode => editingOrderId != null;

  String get formattedBookingNo {
    if (_editingOrderNo != null) return _editingOrderNo!;
    if (_isNumberLoading) return 'Loading...';
    return _repo.formatBookingNumber(
      shopCode: _shopDocumentCode,
      yearToken: _currentYearToken,
      sequence: _nextSequence,
      documentPrefix: _billingSettings.documentPrefix,
    );
  }

  Future<void> _initBookingNumber() async {
    try {
      final settings = await _repo.fetchBillingSettings();
      final shopCode = await _repo.resolveShopDocumentCode();
      final yearToken = _repo.getCurrentDocumentYearToken();
      final seq = await _repo.getNextBookingSequence(
        shopCode: shopCode,
        yearToken: yearToken,
        documentPrefix: settings.documentPrefix,
      );
      _billingSettings = settings;
      _shopDocumentCode = shopCode;
      _currentYearToken = yearToken;
      _nextSequence = seq;
      _isNumberLoading = false;
      _applyBillingDefaults();
      notifyListeners();
    } catch (e) {
      AppLogger.debug('Booking number init error: $e');
      _shopDocumentCode = 'SH';
      _currentYearToken = _repo.getCurrentDocumentYearToken();
      _nextSequence = 1;
      _isNumberLoading = false;
      _applyBillingDefaults();
      notifyListeners();
    }
  }

  BookingType bookingType = BookingType.open;
  DateTime? deliveryDate;

  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  int? selectedCustomerId;
  String _selectedCustomerMobile = '';
  String _selectedCustomerName = '';

  final List<BookingItemModel> bookingItems = [];
  final ScrollController tableScrollCtrl = ScrollController();
  int activeItemIndex = -1;

  final List<BookingScrapModel> scrapItems = [];

  final TextEditingController lockedRateCtrl = TextEditingController();
  double get lockedRate => _p(lockedRateCtrl.text);

  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();
  double _cashInput = 0.0;
  double _upiInput = 0.0;
  double _cardInput = 0.0;

  bool isSaving = false;

  List<Map<String, dynamic>> customerResults = [];
  bool customerNotFound = false;
  bool isSearching = false;
  Timer? _searchTimer;

  bool get showLockedRate => bookingType == BookingType.locked;
  double get cashAdvance => _cashInput;
  double get upiAdvance => _upiInput;
  double get cardAdvance => _cardInput;
  double get totalCashAdv => _cashInput + _upiInput + _cardInput;

  double get totalScrapVal => scrapItems.fold(0.0, (s, i) => s + i.totalValue);

  double get totalAdvance => totalCashAdv + totalScrapVal;
  double get totalBookingVal =>
      bookingItems.fold(0.0, (s, i) => s + i.totalValue);

  double get totalBookingGoldWt => bookingItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0.0, (s, i) => s + i.netWt);
  double get totalBookingSilverWt => bookingItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0.0, (s, i) => s + i.netWt);

  double get totalScrapGoldWt => scrapItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0.0, (s, i) => s + i.netWt);
  double get totalScrapSilverWt => scrapItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0.0, (s, i) => s + i.netWt);

  void toggleBookingType(BookingType type) => _toggleBookingType(type);

  void setDeliveryDate(DateTime? date) => _setDeliveryDate(date);

  void addBookingItem() => _addBookingItem();

  void removeBookingItem(int index) => _removeBookingItem(index);

  void removeActiveItem() => _removeActiveItem();

  void addScrapItem() => _addScrapItem();

  void removeScrapItem(int index) => _removeScrapItem(index);

  void searchCustomer(String query) => _searchCustomer(query);

  void handleCustomerLookupInput(String query) =>
      _handleCustomerLookupInput(query);

  void clearCustomerDetails() => _clearCustomerDetails();

  void selectCustomerFromSearch(Map<String, dynamic> customer) =>
      _selectCustomerFromSearch(customer);

  Future<bool> initializeForEdit(int orderId) => _initializeForEdit(orderId);

  Future<
      ({
        bool success,
        String message,
        String bookingNo,
        List<int> orderIds,
      })> saveBooking() => _saveBooking();

  Future<BookingInvoiceDraftResult> buildInvoicePreviewDraft() =>
      _buildInvoicePreviewDraft();

  void clearAll() => _clearAllAndNotify();

  void _emitChanged() {
    notifyListeners();
  }

  void _onChildChanged() {
    _syncSmartRatePreference();
    notifyListeners();
  }

  void _syncSmartRatePreference() {
    final metalRateText = _ratePreferencePolicy.firstMetalRateText(
      bookingItems,
    );
    if (metalRateText != null) {
      bookingType = BookingType.locked;
      if (lockedRateCtrl.text.trim() != metalRateText) {
        lockedRateCtrl.text = metalRateText;
      }
      return;
    }

    if (bookingType == BookingType.locked) {
      bookingType = BookingType.open;
    }
    if (lockedRateCtrl.text.isNotEmpty) {
      lockedRateCtrl.clear();
    }
  }

  void _applyBillingDefaults() {
    if (isEditMode) return;
    bookingType = _billingSettings.defaultBookingType ==
            BookingAdvanceBillingModel.bookingTypeLocked
        ? BookingType.locked
        : BookingType.open;
    final days = _billingSettings.defaultDeliveryDays;
    deliveryDate = days <= 0 ? null : DateTime.now().add(Duration(days: days));
  }

  String? _minimumAdvanceValidationMessage() {
    final settings = _billingSettings;
    if (settings.allowZeroAdvance) return null;
    final requiredByPercent =
        totalBookingVal * (settings.minimumAdvancePercent / 100);
    final requiredAdvance = requiredByPercent > settings.minimumAdvanceAmount
        ? requiredByPercent
        : settings.minimumAdvanceAmount;
    if (requiredAdvance <= 0 && totalAdvance > 0) return null;
    if (requiredAdvance <= 0 && totalAdvance <= 0) {
      return 'Please enter an advance amount for this booking.';
    }
    if (totalAdvance + 0.005 < requiredAdvance) {
      return 'Minimum advance required is Rs. ${_formatNumber(requiredAdvance)}.';
    }
    return null;
  }

  double _p(String t) =>
      double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  double _lockedRateForItem(BookingItemModel item) {
    return item.rate > 0 ? item.rate : lockedRate;
  }

  String _formatNumber(double value) {
    if (value.abs() < 0.0001) return '';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) return rounded.toStringAsFixed(0);
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  MetalType _metalFromLabel(String label) {
    final normalized = label.trim().toUpperCase();
    for (final metal in MetalType.values) {
      if (metal.displayName == normalized ||
          metal.name.toUpperCase() == normalized) {
        return metal;
      }
    }
    return MetalType.gold;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    tableScrollCtrl.dispose();
    mobileCtrl.dispose();
    nameCtrl.dispose();
    cityCtrl.dispose();
    lockedRateCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    cardCtrl.dispose();
    for (final i in bookingItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    for (final i in scrapItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    super.dispose();
  }
}
