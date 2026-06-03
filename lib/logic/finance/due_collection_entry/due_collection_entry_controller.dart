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
    notesCtrl.addListener(_notifyListeners);
    _loadBankAccounts();
    _startWatch();
  }

  final DueCollectionEntryRepository _repository;
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  StreamSubscription<List<DueCollectionBillModel>>? _watchSub;

  bool _disposed = false;
  List<DueCollectionBillModel> _allBills = [];
  List<DueCollectionBillModel> _bills = [];
  List<DueCollectionBankAccountModel> _bankAccounts = [];
  DueCollectionBillModel? _selectedBill;
  DueCollectionStatsModel _stats = DueCollectionStatsModel.empty();
  DueCollectionPaymentMode _paymentMode = DueCollectionPaymentMode.cash;
  int? _selectedBankAccountId;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String? _lastReceiptNo;
  double _amount = 0;

  List<DueCollectionBillModel> get bills => _bills;
  List<DueCollectionBankAccountModel> get bankAccounts => _bankAccounts;
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
  int get allBillCount => _allBills.length;
  double get amount => _amount;

  bool get requiresBankAccount => _paymentMode.usesBankLedger;
  bool get hasBankAccount =>
      !requiresBankAccount || _selectedBankAccountId != null;
  bool get canSave {
    final bill = _selectedBill;
    return !_isSaving &&
        bill != null &&
        _amount > 0 &&
        _amount <= bill.dueAmount + 0.01 &&
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

  void selectBill(DueCollectionBillModel bill) {
    _selectedBill = bill;
    setFullDueAmount();
    _successMessage = null;
    _errorMessage = null;
    _applyViewState();
  }

  void setPaymentMode(DueCollectionPaymentMode value) {
    if (_paymentMode == value) return;
    _paymentMode = value;
    if (value.usesBankLedger &&
        _selectedBankAccountId == null &&
        _bankAccounts.isNotEmpty) {
      _selectedBankAccountId = _bankAccounts.first.id;
    }
    _notifyListeners();
  }

  void setBankAccount(int? value) {
    _selectedBankAccountId = value;
    _notifyListeners();
  }

  void setFullDueAmount() {
    final due = _selectedBill?.dueAmount ?? 0;
    amountCtrl.text = due <= 0 ? '' : due.toStringAsFixed(2);
  }

  void setHalfDueAmount() {
    final due = _selectedBill?.dueAmount ?? 0;
    amountCtrl.text = due <= 0 ? '' : (due / 2).toStringAsFixed(2);
  }

  void clearSearch() {
    searchCtrl.clear();
  }

  void resetEntry() {
    _selectedBill = _bills.isEmpty ? null : _bills.first;
    _paymentMode = DueCollectionPaymentMode.cash;
    _successMessage = null;
    _errorMessage = null;
    _lastReceiptNo = null;
    notesCtrl.clear();
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
    if (_amount > bill.dueAmount + 0.01) {
      return DueCollectionSaveResult(
        success: false,
        message: 'Amount cannot exceed due ${formatAmount(bill.dueAmount)}.',
      );
    }
    if (requiresBankAccount && _selectedBankAccountId == null) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Select bank account for this payment mode.',
      );
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();

    final result = await _repository.saveCollection(
      billId: bill.id,
      amount: _amount,
      mode: _paymentMode,
      bankAccountId: _selectedBankAccountId,
      notes: notesCtrl.text,
    );

    if (_disposed) return result;
    _isSaving = false;
    if (result.success) {
      _successMessage = result.message;
      _lastReceiptNo = result.receiptNo;
      notesCtrl.clear();
      amountCtrl.clear();
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
    _syncSelection();
    _stats = DueCollectionStatsModel.fromBills(_bills, _selectedBill);
    _notifyListeners();
  }

  void _syncSelection() {
    final previousId = _selectedBill?.id;
    if (_bills.isEmpty) {
      _selectedBill = null;
      return;
    }
    if (previousId != null) {
      for (final bill in _bills) {
        if (bill.id == previousId) {
          _selectedBill = bill;
          return;
        }
      }
    }
    _selectedBill = _bills.first;
    if (amountCtrl.text.trim().isEmpty) setFullDueAmount();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchSub?.cancel();
    searchCtrl.removeListener(_onSearchChanged);
    amountCtrl.removeListener(_onAmountChanged);
    notesCtrl.removeListener(_notifyListeners);
    searchCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}
