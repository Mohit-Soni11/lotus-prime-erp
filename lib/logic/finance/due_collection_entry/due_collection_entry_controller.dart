import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../../../repositories/finance/due_collection_entry_repository.dart';

class DueCollectionEntryController extends ChangeNotifier {
  DueCollectionEntryController({DueCollectionEntryRepository? repository})
      : _repository = repository ?? DueCollectionEntryRepository() {
    searchCtrl.addListener(_onSearchChanged);
    amountCtrl.addListener(_onAmountChanged);
    discountCtrl.addListener(_onDiscountChanged);
    notesCtrl.addListener(_notifyListeners);
    _loadBankAccounts();
    _startWatch();
  }

  final DueCollectionEntryRepository _repository;
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  StreamSubscription<List<DueCollectionBillModel>>? _watchSub;

  bool _disposed = false;
  List<DueCollectionBillModel> _allBills = [];
  List<DueCollectionBillModel> _bills = [];
  List<DueCollectionCustomerModel> _customers = [];
  List<DueCollectionBankAccountModel> _bankAccounts = [];
  DueCollectionCustomerModel? _selectedCustomer;
  DueCollectionBillModel? _selectedBill;
  DueCollectionStatsModel _stats = DueCollectionStatsModel.empty();
  DueCollectionPaymentMode _paymentMode = DueCollectionPaymentMode.cash;
  int? _selectedBankAccountId;
  String? _selectedCustomerKey;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String? _lastReceiptNo;
  String? _lastPaymentModeLabel;
  DateTime? _promiseDate;
  DateTime? _lastPromiseDate;
  double _lastCollectedAmount = 0;
  double _lastDiscountAmount = 0;
  double _lastBalanceDue = 0;
  double _amount = 0;
  double _discountAmount = 0;

  List<DueCollectionBillModel> get bills => _bills;
  List<DueCollectionCustomerModel> get customers => _customers;
  List<DueCollectionBillModel> get selectedCustomerBills =>
      _selectedCustomer?.bills ?? const [];
  List<DueCollectionBankAccountModel> get bankAccounts => _bankAccounts;
  DueCollectionCustomerModel? get selectedCustomer => _selectedCustomer;
  DueCollectionBillModel? get selectedBill => _selectedBill;
  DueCollectionStatsModel get stats => _stats;
  DueCollectionPaymentMode get paymentMode => _paymentMode;
  int? get selectedBankAccountId => _selectedBankAccountId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get lastReceiptNo => _lastReceiptNo;
  String? get lastPaymentModeLabel => _lastPaymentModeLabel;
  DateTime? get promiseDate => _promiseDate;
  DateTime? get lastPromiseDate => _lastPromiseDate;
  double get lastCollectedAmount => _lastCollectedAmount;
  double get lastDiscountAmount => _lastDiscountAmount;
  double get lastBalanceDue => _lastBalanceDue;
  int get allBillCount => _allBills.length;
  double get amount => _amount;
  double get discountAmount => _discountAmount;
  double get settlementAmount => _amount + _discountAmount;
  double get balanceAfterSave {
    final bill = _selectedBill;
    if (bill == null) return 0;
    return (bill.dueAmount - settlementAmount).clamp(0.0, double.infinity);
  }

  bool get requiresBankAccount => _paymentMode.usesBankLedger;
  bool get hasBankAccount =>
      !requiresBankAccount || _selectedBankAccountId != null;
  bool get needsPromiseDate => _selectedBill != null && balanceAfterSave > 0.5;
  bool get canSave {
    final bill = _selectedBill;
    return !_isSaving &&
        bill != null &&
        _amount > 0 &&
        _discountAmount >= 0 &&
        settlementAmount > 0 &&
        settlementAmount <= bill.dueAmount + 0.01 &&
        (!needsPromiseDate || _promiseDate != null) &&
        hasBankAccount;
  }

  static final NumberFormat _amountFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _compactFmt = NumberFormat('#,##,##0', 'en_IN');
  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFmt = DateFormat('dd MMM');

  static String formatAmount(double amount) =>
      'Rs ${_amountFmt.format(amount)}';
  static String formatCompact(double amount) =>
      'Rs ${_compactFmt.format(amount)}';
  static String formatInputAmount(double amount) => _amountFmt.format(amount);
  static String formatDate(DateTime? date) =>
      date == null ? '-' : _dateFmt.format(date);
  static String formatShortDate(DateTime? date) =>
      date == null ? '-' : _shortDateFmt.format(date);

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void _startWatch() {
    _watchSub?.cancel();
    _watchSub = _repository.watchDueBills().listen(
      (bills) {
        if (_disposed) return;
        _allBills = bills;
        _isLoading = false;
        _errorMessage = null;
        _applyViewState();
      },
      onError: (_) {
        if (_disposed) return;
        _isLoading = false;
        _errorMessage = 'Unable to load due bills.';
        _notifyListeners();
      },
    );
  }

  Future<void> _loadBankAccounts() async {
    final accounts = await _repository.fetchBankAccounts();
    if (_disposed) return;
    _bankAccounts = accounts;
    _selectedBankAccountId = accounts.isEmpty ? null : accounts.first.id;
    _notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final results = await Future.wait([
      _repository.fetchDueBills(),
      _repository.fetchBankAccounts(),
    ]);
    if (_disposed) return;
    _allBills = results[0] as List<DueCollectionBillModel>;
    _bankAccounts = results[1] as List<DueCollectionBankAccountModel>;
    _selectedBankAccountId ??=
        _bankAccounts.isEmpty ? null : _bankAccounts.first.id;
    _isLoading = false;
    _applyViewState();
  }

  void selectCustomer(DueCollectionCustomerModel customer) {
    _selectedCustomerKey = customer.key;
    _selectedCustomer = customer;
    _selectBillInternal(customer.firstBill, resetInputs: true, notify: false);
    _stats = DueCollectionStatsModel.fromBills(_bills, _selectedBill);
    _notifyListeners();
  }

  void selectBill(DueCollectionBillModel bill) {
    _selectedCustomerKey = DueCollectionCustomerModel.keyForBill(bill);
    _selectBillInternal(bill, resetInputs: true, notify: true);
  }

  void setPaymentMode(DueCollectionPaymentMode value) {
    if (_paymentMode == value) return;
    _paymentMode = value;
    if (value.usesBankLedger &&
        _selectedBankAccountId == null &&
        _bankAccounts.isNotEmpty) {
      _selectedBankAccountId = _bankAccounts.first.id;
    }
    _clearReceiptState();
    _notifyListeners();
  }

  void setBankAccount(int? value) {
    _selectedBankAccountId = value;
    _notifyListeners();
  }

  void setFullDueAmount() {
    final due = _selectedBill?.dueAmount ?? 0;
    final value = (due - _discountAmount).clamp(0.0, double.infinity);
    amountCtrl.text = value <= 0 ? '' : formatInputAmount(value);
  }

  void setHalfDueAmount() {
    final due = _selectedBill?.dueAmount ?? 0;
    amountCtrl.text = due <= 0 ? '' : formatInputAmount(due / 2);
  }

  void clearDiscount() {
    discountCtrl.clear();
  }

  void setPromiseDate(DateTime? value) {
    _promiseDate = value == null ? null : DueCollectionDate.only(value);
    _clearReceiptState();
    _notifyListeners();
  }

  void setQuickPromiseDays(int days) {
    setPromiseDate(DateTime.now().add(Duration(days: days)));
  }

  void clearSearch() {
    searchCtrl.clear();
  }

  void resetEntry() {
    _selectedCustomerKey = null;
    _selectedCustomer = _customers.isEmpty ? null : _customers.first;
    _selectedBill = _selectedCustomer?.firstBill;
    _paymentMode = DueCollectionPaymentMode.cash;
    _successMessage = null;
    _errorMessage = null;
    _clearReceiptState();
    notesCtrl.clear();
    discountCtrl.clear();
    _promiseDate = _selectedBill?.promiseDate;
    setFullDueAmount();
    _applyViewState();
  }

  Future<DueCollectionSaveResult> saveCollection() async {
    final bill = _selectedBill;
    if (bill == null) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Select a due bill first.',
      );
    }
    if (_amount <= 0) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Enter collection amount.',
      );
    }
    if (_discountAmount < 0) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Discount cannot be negative.',
      );
    }
    if (settlementAmount > bill.dueAmount + 0.01) {
      return DueCollectionSaveResult(
        success: false,
        message:
            'Amount + discount cannot exceed due ${formatAmount(bill.dueAmount)}.',
      );
    }
    if (needsPromiseDate && _promiseDate == null) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Select next promise date for remaining due.',
      );
    }
    if (requiresBankAccount && _selectedBankAccountId == null) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Select bank account for this payment mode.',
      );
    }

    final receivedBeforeSave = _amount;
    final discountBeforeSave = _discountAmount;
    final balanceBeforeSave = balanceAfterSave;
    final modeLabelBeforeSave = _paymentMode.label;
    final promiseBeforeSave = _promiseDate;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();

    final result = await _repository.saveCollection(
      billId: bill.id,
      amount: receivedBeforeSave,
      discountAmount: discountBeforeSave,
      mode: _paymentMode,
      bankAccountId: _selectedBankAccountId,
      nextPromiseDate: promiseBeforeSave,
      notes: notesCtrl.text,
    );

    if (_disposed) return result;
    _isSaving = false;
    if (result.success) {
      _successMessage = result.message;
      notesCtrl.clear();
      amountCtrl.clear();
      discountCtrl.clear();
      _promiseDate = null;
      _lastReceiptNo = result.receiptNo;
      _lastCollectedAmount = receivedBeforeSave;
      _lastDiscountAmount = discountBeforeSave;
      _lastBalanceDue = balanceBeforeSave;
      _lastPaymentModeLabel = modeLabelBeforeSave;
      _lastPromiseDate = promiseBeforeSave;
    } else {
      _errorMessage = result.message;
    }
    _notifyListeners();
    return result;
  }

  void _onSearchChanged() {
    if (_disposed) return;
    _searchQuery = searchCtrl.text.trim();
    _applyViewState();
  }

  void _onAmountChanged() {
    if (_disposed) return;
    _amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    _clearReceiptState();
    _notifyListeners();
  }

  void _onDiscountChanged() {
    if (_disposed) return;
    _discountAmount =
        double.tryParse(discountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    _clearReceiptState();
    _notifyListeners();
  }

  void _applyViewState() {
    if (_disposed) return;
    var visible = List<DueCollectionBillModel>.from(_allBills);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      visible = visible.where((bill) {
        return bill.customerName.toLowerCase().contains(q) ||
            bill.mobile.toLowerCase().contains(q) ||
            bill.billNo.toLowerCase().contains(q) ||
            bill.city.toLowerCase().contains(q) ||
            bill.address.toLowerCase().contains(q);
      }).toList();
    }

    _bills = visible;
    _customers = DueCollectionCustomerModel.groupBills(visible);
    _syncCustomerAndBill();
    _stats = DueCollectionStatsModel.fromBills(_bills, _selectedBill);
    _notifyListeners();
  }

  void _syncCustomerAndBill() {
    final previousBillId = _selectedBill?.id;
    if (_customers.isEmpty) {
      _selectedCustomer = null;
      _selectedBill = null;
      _selectedCustomerKey = null;
      return;
    }

    final exactBill = _findExactInvoiceMatch();
    if (exactBill != null) {
      _selectedCustomerKey = DueCollectionCustomerModel.keyForBill(exactBill);
      _selectedCustomer = _findCustomerByKey(_selectedCustomerKey!);
      _selectedBill = exactBill;
      if (previousBillId != exactBill.id || amountCtrl.text.trim().isEmpty) {
        _prepareBillInputs(exactBill);
      }
      return;
    }

    DueCollectionCustomerModel? customer;
    if (_selectedCustomerKey != null) {
      customer = _findCustomerByKey(_selectedCustomerKey!);
    }
    if (customer == null && previousBillId != null) {
      customer = _findCustomerContainingBill(previousBillId);
    }
    customer ??= _customers.first;

    _selectedCustomer = customer;
    _selectedCustomerKey = customer.key;

    DueCollectionBillModel? bill;
    if (previousBillId != null) {
      for (final item in customer.bills) {
        if (item.id == previousBillId) {
          bill = item;
          break;
        }
      }
    }
    bill ??= customer.firstBill;
    _selectedBill = bill;

    if (previousBillId != bill.id || amountCtrl.text.trim().isEmpty) {
      _prepareBillInputs(bill);
    }
  }

  DueCollectionBillModel? _findExactInvoiceMatch() {
    if (_searchQuery.isEmpty) return null;
    final q = _searchQuery.toLowerCase();
    for (final bill in _bills) {
      if (bill.billNo.toLowerCase() == q) return bill;
    }
    return null;
  }

  DueCollectionCustomerModel? _findCustomerByKey(String key) {
    for (final customer in _customers) {
      if (customer.key == key) return customer;
    }
    return null;
  }

  DueCollectionCustomerModel? _findCustomerContainingBill(int billId) {
    for (final customer in _customers) {
      for (final bill in customer.bills) {
        if (bill.id == billId) return customer;
      }
    }
    return null;
  }

  void _selectBillInternal(
    DueCollectionBillModel bill, {
    required bool resetInputs,
    required bool notify,
  }) {
    _selectedBill = bill;
    _selectedCustomerKey = DueCollectionCustomerModel.keyForBill(bill);
    _selectedCustomer = _findCustomerByKey(_selectedCustomerKey!) ??
        _selectedCustomer ??
        (_customers.isEmpty ? null : _customers.first);
    _successMessage = null;
    _errorMessage = null;
    _clearReceiptState();
    if (resetInputs) _prepareBillInputs(bill);
    _stats = DueCollectionStatsModel.fromBills(_bills, _selectedBill);
    if (notify) _notifyListeners();
  }

  void _prepareBillInputs(DueCollectionBillModel bill) {
    _promiseDate = bill.promiseDate;
    discountCtrl.clear();
    setFullDueAmount();
  }

  void _clearReceiptState() {
    _lastReceiptNo = null;
    _lastCollectedAmount = 0;
    _lastDiscountAmount = 0;
    _lastBalanceDue = 0;
    _lastPaymentModeLabel = null;
    _lastPromiseDate = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _watchSub?.cancel();
    searchCtrl.removeListener(_onSearchChanged);
    amountCtrl.removeListener(_onAmountChanged);
    discountCtrl.removeListener(_onDiscountChanged);
    notesCtrl.removeListener(_notifyListeners);
    searchCtrl.dispose();
    amountCtrl.dispose();
    discountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}
