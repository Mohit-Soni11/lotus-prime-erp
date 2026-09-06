// =============================================================================
// FILE        : booking_advance_controller.dart
// MODULE      : Sales / Booking & Advance
// LAYER       : Application Controller
// DESCRIPTION : Coordinates booking entry state, validation, and persistence.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/booking_advance/booking_advance/booking_advance_model.dart';
import '../../repositories/booking_advance/booking_advance_repository.dart';
import '../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum BookingType { open, locked }

class BookingAdvanceController extends ChangeNotifier {
  final BookingAdvanceRepository _repo;

  BookingAdvanceController({BookingAdvanceRepository? repo})
      : _repo = repo ?? BookingAdvanceRepository() {
    cashCtrl.addListener(() {
      _cashInput = _p(cashCtrl.text);
      notifyListeners();
    });
    upiCtrl.addListener(() {
      _upiInput = _p(upiCtrl.text);
      notifyListeners();
    });
    cardCtrl.addListener(() {
      _cardInput = _p(cardCtrl.text);
      notifyListeners();
    });
    lockedRateCtrl.addListener(notifyListeners);

    _initBookingNumber();
  }

  String _shopDocumentCode = 'SH';
  String _currentYearToken = '';
  int _nextSequence = 0;
  bool _isNumberLoading = true;

  bool get isNumberLoading => _isNumberLoading;
  String get currentFinancialYear => _currentYearToken;
  int get nextSequence => _nextSequence;
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
    );
  }

  Future<void> _initBookingNumber() async {
    try {
      final shopCode = await _repo.resolveShopDocumentCode();
      final yearToken = _repo.getCurrentDocumentYearToken();
      final seq = await _repo.getNextBookingSequence(
        shopCode: shopCode,
        yearToken: yearToken,
      );
      _shopDocumentCode = shopCode;
      _currentYearToken = yearToken;
      _nextSequence = seq;
      _isNumberLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.debug('Booking number init error: $e');
      _shopDocumentCode = 'SH';
      _currentYearToken = _repo.getCurrentDocumentYearToken();
      _nextSequence = 1;
      _isNumberLoading = false;
      notifyListeners();
    }
  }

  BookingType bookingType = BookingType.open;
  DateTime? deliveryDate;

  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();
  int? selectedCustomerId;

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
  double get balanceDue => totalBookingVal - totalAdvance;

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

  void toggleBookingType(BookingType t) {
    bookingType = t;
    if (t == BookingType.open) lockedRateCtrl.clear();
    notifyListeners();
  }

  void setDeliveryDate(DateTime? d) {
    deliveryDate = d;
    notifyListeners();
  }

  void _onChildChanged() => notifyListeners();

  void addBookingItem() {
    final item = BookingItemModel();
    item.addListener(_onChildChanged);
    bookingItems.add(item);
    activeItemIndex = bookingItems.length - 1;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (tableScrollCtrl.hasClients) {
        tableScrollCtrl.animateTo(
          tableScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      item.firstFieldFocus.requestFocus();
    });
  }

  void removeBookingItem(int index) {
    if (index < 0 || index >= bookingItems.length) return;
    bookingItems[index].removeListener(_onChildChanged);
    bookingItems[index].dispose();
    bookingItems.removeAt(index);
    if (activeItemIndex >= bookingItems.length) {
      activeItemIndex = bookingItems.length - 1;
    }
    notifyListeners();
  }

  void removeActiveItem() {
    if (activeItemIndex != -1 && bookingItems.isNotEmpty) {
      final idx = activeItemIndex;
      removeBookingItem(idx);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (bookingItems.isNotEmpty) {
          final fi = idx > 0 ? idx - 1 : 0;
          bookingItems[fi].firstFieldFocus.requestFocus();
          activeItemIndex = fi;
        }
      });
    }
  }

  void addScrapItem() {
    final item = BookingScrapModel();
    item.addListener(_onChildChanged);
    scrapItems.add(item);
    notifyListeners();
  }

  void removeScrapItem(int index) {
    if (index < 0 || index >= scrapItems.length) return;
    scrapItems[index].removeListener(_onChildChanged);
    scrapItems[index].dispose();
    scrapItems.removeAt(index);
    notifyListeners();
  }

  void searchCustomer(String query) {
    _searchTimer?.cancel();
    if (query.length < 2) {
      customerResults = [];
      notifyListeners();
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      isSearching = true;
      notifyListeners();
      try {
        customerResults = await _repo.searchCustomers(query);
      } catch (_) {
        customerResults = [];
      }
      isSearching = false;
      notifyListeners();
    });
  }

  void selectCustomerFromSearch(Map<String, dynamic> c) {
    selectedCustomerId = c['id'];
    mobileCtrl.text = c['mobile'] ?? '';
    nameCtrl.text = c['name'] ?? '';
    cityCtrl.text = c['city'] ?? '';
    customerResults = [];
    notifyListeners();
  }

  Future<bool> initializeForEdit(int orderId) async {
    isLoadingEditOrder = true;
    editLoadError = null;
    notifyListeners();

    try {
      final details = await _repo.fetchEditableBooking(orderId);
      if (details == null) {
        editLoadError = 'Advance order could not be loaded for editing.';
        return false;
      }

      _clearAll();
      final order = details.order;
      editingOrderId = order.id;
      _editingOrderNo = order.orderNo;
      selectedCustomerId = order.customerId;

      final customer = details.customer;
      if (customer != null) {
        mobileCtrl.text = customer.mobile;
        nameCtrl.text = customer.name;
        cityCtrl.text = customer.city ?? '';
      }

      bookingType = order.bookingType.toUpperCase() == 'LOCKED'
          ? BookingType.locked
          : BookingType.open;
      lockedRateCtrl.text = _formatNumber(order.lockedRate);
      deliveryDate = order.deliveryDate;

      final item = BookingItemModel(metal: _metalFromLabel(order.metalType));
      item.addListener(_onChildChanged);
      item.descCtrl.text = order.itemName;
      item.purityCtrl.text = order.purity;
      item.grossCtrl.text = _formatNumber(order.approxWeight);
      item.lessCtrl.text = '';
      item.rateCtrl.text = _formatNumber(order.lockedRate);
      bookingItems.add(item);
      activeItemIndex = 0;

      final totalAdvance =
          details.advances.fold<double>(0, (sum, row) => sum + row.amountPaid);
      cashCtrl.text = _formatNumber(totalAdvance);
      _cashInput = totalAdvance;
      if (details.advances.isNotEmpty && lockedRateCtrl.text.isEmpty) {
        lockedRateCtrl.text = _formatNumber(details.advances.first.rateOnDate);
      }

      notifyListeners();
      return true;
    } catch (error) {
      editLoadError = 'Advance order could not be loaded for editing.';
      return false;
    } finally {
      isLoadingEditOrder = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message, String bookingNo})>
      saveBooking() async {
    if (nameCtrl.text.trim().isEmpty) {
      return (
        success: false,
        message: 'Please enter customer name.',
        bookingNo: '',
      );
    }
    if (bookingItems.isEmpty) {
      return (
        success: false,
        message: 'Please add at least one booking item.',
        bookingNo: '',
      );
    }
    if (bookingType == BookingType.locked && lockedRate <= 0) {
      return (
        success: false,
        message: 'Please enter a valid locked rate.',
        bookingNo: '',
      );
    }
    for (var index = 0; index < bookingItems.length; index++) {
      final item = bookingItems[index];
      if (item.netWt <= 0) {
        return (
          success: false,
          message: 'Please enter valid net weight for item ${index + 1}.',
          bookingNo: '',
        );
      }
    }

    isSaving = true;
    notifyListeners();

    try {
      if (_isNumberLoading) {
        await _initBookingNumber();
      }

      final customerId = await _repo.resolveCustomerForBooking(
        selectedCustomerId: selectedCustomerId,
        customerName: nameCtrl.text,
        customerMobile: mobileCtrl.text,
        city: cityCtrl.text,
        panNumber: panCtrl.text,
        gstNumber: gstCtrl.text,
      );
      selectedCustomerId = customerId;

      final savedBookingNo = formattedBookingNo;
      final perItemAdv = bookingItems.isEmpty
          ? totalAdvance
          : totalAdvance / bookingItems.length;

      if (editingOrderId != null) {
        final item = bookingItems.first;
        await _repo.updateBooking(
          orderId: editingOrderId!,
          customerId: customerId,
          itemName: item.descCtrl.text.trim().isEmpty
              ? '${item.metal.displayName} Item'
              : item.descCtrl.text.trim(),
          metalType: item.metal.displayName,
          purity: item.purityCtrl.text.isEmpty ? '22K' : item.purityCtrl.text,
          approxWeight: item.netWt,
          bookingType: bookingType == BookingType.locked ? 'LOCKED' : 'OPEN',
          lockedRate: bookingType == BookingType.locked ? lockedRate : 0.0,
          deliveryDate: deliveryDate,
          notes: null,
          totalAdvance: totalAdvance,
          rateOnDate: _p(item.rateCtrl.text),
        );

        _clearAll();
        isSaving = false;
        notifyListeners();

        return (
          success: true,
          message: 'Booking $savedBookingNo updated successfully!',
          bookingNo: savedBookingNo,
        );
      }

      for (final item in bookingItems) {
        await _repo.saveNewBooking(
          customerId: customerId,
          customerName: nameCtrl.text.trim(),
          customerMobile: mobileCtrl.text.trim(),
          itemName: item.descCtrl.text.trim().isEmpty
              ? '${item.metal.displayName} Item'
              : item.descCtrl.text.trim(),
          itemDesc: '',
          metalType: item.metal.displayName,
          purity: item.purityCtrl.text.isEmpty ? '22K' : item.purityCtrl.text,
          approxWeight: item.netWt,
          bookingType: bookingType == BookingType.locked ? 'LOCKED' : 'OPEN',
          lockedRate: bookingType == BookingType.locked ? lockedRate : 0.0,
          deliveryDate: deliveryDate,
          notes: null,
          totalAdvance: perItemAdv,
          goldRate: _p(item.rateCtrl.text),
          isGst: false,
        );
      }

      // Re-sync booking number from DB after successful save
      await _initBookingNumber();

      _clearAll();
      isSaving = false;
      notifyListeners();

      return (
        success: true,
        message: 'Booking $savedBookingNo saved successfully!',
        bookingNo: savedBookingNo,
      );
    } catch (e) {
      isSaving = false;
      notifyListeners();
      AppLogger.debug('Booking save error: $e');
      return (
        success: false,
        message: 'Failed to save. Please try again.',
        bookingNo: '',
      );
    }
  }

  void clearAll() {
    _clearAll();
    notifyListeners();
  }

  void _clearAll() {
    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    panCtrl.clear();
    gstCtrl.clear();
    lockedRateCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    _cashInput = 0;
    _upiInput = 0;
    _cardInput = 0;
    selectedCustomerId = null;
    editingOrderId = null;
    _editingOrderNo = null;
    editLoadError = null;
    bookingType = BookingType.open;
    deliveryDate = null;
    customerResults = [];
    for (final i in bookingItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    for (final i in scrapItems) {
      i.removeListener(_onChildChanged);
      i.dispose();
    }
    bookingItems.clear();
    scrapItems.clear();
    activeItemIndex = -1;
  }

  double _p(String t) =>
      double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

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
    panCtrl.dispose();
    gstCtrl.dispose();
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
