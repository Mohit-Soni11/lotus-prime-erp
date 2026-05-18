import 'package:flutter/material.dart';

import '../../database/db/app_database.dart';
import '../../helpers/search/fuzzy_search_helper.dart';
import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../models/stock/supplier_model/supplier_model.dart';
import '../../repositories/purchase/purchase_entry_repository.dart';
import '../../repositories/supplier/supplier_repository.dart';

class PurchaseEntryController extends ChangeNotifier {
  PurchaseEntryController() {
    _init();
    _addPaymentListeners();
  }

  final AppDatabase _db = AppDatabase();
  late final SupplierRepository _supplierRepository = SupplierRepository(_db);
  late final PurchaseEntryRepository _purchaseRepository =
      PurchaseEntryRepository(db: _db);

  PurchaseSource purchaseSource = PurchaseSource.fromCustomer;
  PurchaseTaxType taxType = PurchaseTaxType.normal;
  PurchaseDiscountType discountType = PurchaseDiscountType.flatAmount;

  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();

  final List<PurchaseItemModel> items = [];

  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();

  final ScrollController tableScrollCtrl = ScrollController();

  List<CustomerListItemModel> customerSuggestions = [];
  List<SupplierListItemModel> supplierSuggestions = [];
  CustomerListItemModel? selectedCustomer;
  SupplierListItemModel? selectedSupplier;
  bool counterpartNotFound = false;

  bool _isSaving = false;
  bool _disposed = false;
  String? _saveErrorMessage;
  int _purchaseNo = 1;

  bool get isSaving => _isSaving;
  String? get saveErrorMessage => _saveErrorMessage;
  String get formattedPurchaseNo =>
      'PUR-${DateTime.now().year}-${_purchaseNo.toString().padLeft(4, '0')}';

  bool get hasSelectedCounterparty =>
      purchaseSource == PurchaseSource.fromCustomer
          ? selectedCustomer != null
          : selectedSupplier != null;

  String? get selectedCounterpartyCaption {
    if (purchaseSource == PurchaseSource.fromCustomer &&
        selectedCustomer != null) {
      return 'Linked seller profile';
    }
    if (purchaseSource == PurchaseSource.fromSupplier &&
        selectedSupplier != null) {
      return 'Linked supplier profile';
    }
    return null;
  }

  List<dynamic> get activeSuggestions =>
      purchaseSource == PurchaseSource.fromCustomer
          ? customerSuggestions
          : supplierSuggestions;

  Future<void> _init() async {
    addItem();
    await _syncNextPurchaseSequence();
  }

  Future<void> _syncNextPurchaseSequence() async {
    _purchaseNo = await _purchaseRepository.getNextSequence();
    notifyListeners();
  }

  void _addPaymentListeners() {
    cashCtrl.addListener(_notify);
    upiCtrl.addListener(_notify);
    cardCtrl.addListener(_notify);
    discountCtrl.addListener(_notify);
  }

  void _notify() => notifyListeners();

  void toggleSource(PurchaseSource source) {
    if (purchaseSource == source) {
      return;
    }
    purchaseSource = source;
    taxType = source == PurchaseSource.fromCustomer
        ? PurchaseTaxType.normal
        : taxType;
    clearCounterpartySelection(clearFields: true);
    clearCounterpartySuggestions();
    notifyListeners();
  }

  void toggleTaxType(PurchaseTaxType type) {
    taxType = type;
    notifyListeners();
  }

  void toggleDiscountType(PurchaseDiscountType type) {
    discountType = type;
    notifyListeners();
  }

  void addItem() {
    final item = PurchaseItemModel();
    item.addListener(_notify);
    items.add(item);
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tableScrollCtrl.hasClients) {
        tableScrollCtrl.animateTo(
          tableScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) {
      return;
    }
    final item = items.removeAt(index);
    item.removeListener(_notify);
    item.dispose();
    notifyListeners();
  }

  Future<void> searchCounterparty(String query) async {
    if (purchaseSource == PurchaseSource.fromCustomer) {
      await searchCustomers(query);
      return;
    }
    await searchSuppliers(query);
  }

  Future<void> searchCustomers(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      clearCounterpartySuggestions();
      return;
    }

    if (selectedCustomer != null) {
      final matchesName = nameCtrl.text.trim() == selectedCustomer!.name;
      final matchesMobile = mobileCtrl.text.trim() == selectedCustomer!.mobile;
      if (matchesName || matchesMobile) {
        return;
      }
      selectedCustomer = null;
    }

    try {
      final rows = await _db.select(_db.customers).get();
      final isNumeric = RegExp(r'^\d+$').hasMatch(term);

      final matched = isNumeric
          ? rows
              .where((row) => row.mobile.toLowerCase().contains(term))
              .toList()
          : FuzzySearchHelper.searchObjects(
              items: rows,
              query: term,
              getSearchText: (row) => '${row.name} ${row.mobile}',
              maxResults: 8,
              threshold: 0.30,
            );

      customerSuggestions = matched
          .map(
            (row) => CustomerListItemModel(
              id: row.id,
              name: row.name,
              mobile: row.mobile,
              city: row.city ?? '',
              type: CustomerType.fromString(row.type),
              billCount: 0,
              createdAt: row.createdAt,
              initials: CustomerListItemModel.buildInitials(row.name),
            ),
          )
          .toList();
      supplierSuggestions = [];
      counterpartNotFound = customerSuggestions.isEmpty;
    } catch (error) {
      debugPrint('Purchase customer search failed: $error');
      customerSuggestions = [];
      counterpartNotFound = false;
    }
    notifyListeners();
  }

  Future<void> searchSuppliers(String query) async {
    final term = query.trim();
    if (term.isEmpty) {
      clearCounterpartySuggestions();
      return;
    }

    if (selectedSupplier != null) {
      final matchesName =
          nameCtrl.text.trim() == selectedSupplier!.businessName;
      final matchesMobile = mobileCtrl.text.trim() == selectedSupplier!.mobile;
      if (matchesName || matchesMobile) {
        return;
      }
      selectedSupplier = null;
    }

    try {
      supplierSuggestions = await _supplierRepository.searchSuppliers(term);
      customerSuggestions = [];
      counterpartNotFound = supplierSuggestions.isEmpty;
    } catch (error) {
      debugPrint('Purchase supplier search failed: $error');
      supplierSuggestions = [];
      counterpartNotFound = false;
    }
    notifyListeners();
  }

  Future<void> selectCustomer(CustomerListItemModel customer) async {
    selectedCustomer = customer;
    selectedSupplier = null;
    customerSuggestions = [];
    supplierSuggestions = [];
    counterpartNotFound = false;

    final fullRow = await (_db.select(
      _db.customers,
    )..where((tbl) => tbl.id.equals(customer.id)))
        .getSingleOrNull();

    nameCtrl.text = customer.name;
    mobileCtrl.text = customer.mobile;
    cityCtrl.text = fullRow?.city ?? customer.city;
    panCtrl.text = fullRow?.panNumber ?? '';
    gstCtrl.text = fullRow?.gstNumber ?? '';
    notifyListeners();
  }

  Future<void> selectSupplier(SupplierListItemModel supplier) async {
    selectedSupplier = supplier;
    selectedCustomer = null;
    customerSuggestions = [];
    supplierSuggestions = [];
    counterpartNotFound = false;

    final fullRow = await _supplierRepository.getById(supplier.id);

    nameCtrl.text = supplier.businessName;
    mobileCtrl.text = supplier.mobile;
    cityCtrl.text = fullRow?.state ?? '';
    panCtrl.text = fullRow?.panNumber ?? '';
    gstCtrl.text = fullRow?.gstNumber ?? '';
    notifyListeners();
  }

  void clearCounterpartySuggestions() {
    customerSuggestions = [];
    supplierSuggestions = [];
    counterpartNotFound = false;
    notifyListeners();
  }

  void clearCounterpartySelection({bool clearFields = false}) {
    selectedCustomer = null;
    selectedSupplier = null;
    counterpartNotFound = false;
    if (clearFields) {
      mobileCtrl.clear();
      nameCtrl.clear();
      cityCtrl.clear();
      panCtrl.clear();
      gstCtrl.clear();
    }
    notifyListeners();
  }

  double get totalGoldValue => _sumByMetal(PurchaseMetalType.gold);
  double get totalSilverValue => _sumByMetal(PurchaseMetalType.silver);
  double get totalPlatinumValue => _sumByMetal(PurchaseMetalType.platinum);
  double get totalDiamondValue => _sumByMetal(PurchaseMetalType.diamond);

  double get totalGoldFine => _fineByMetal(PurchaseMetalType.gold);
  double get totalSilverFine => _fineByMetal(PurchaseMetalType.silver);
  double get totalPlatinumFine => _fineByMetal(PurchaseMetalType.platinum);
  double get totalDiamondFine => _fineByMetal(PurchaseMetalType.diamond);

  double _sumByMetal(PurchaseMetalType metal) {
    return items
        .where((item) => item.metal == metal)
        .fold(0.0, (sum, item) => sum + item.totalValue);
  }

  double _fineByMetal(PurchaseMetalType metal) {
    return items
        .where((item) => item.metal == metal)
        .fold(0.0, (sum, item) => sum + item.fineWt);
  }

  double get grossPurchaseAmount =>
      items.fold(0.0, (sum, item) => sum + item.totalValue);

  double get discountValueInput => _parseAmount(discountCtrl.text);

  double get discountAmount {
    if (discountType == PurchaseDiscountType.percentage) {
      return grossPurchaseAmount * discountValueInput / 100.0;
    }
    return discountValueInput;
  }

  double get taxableAmount =>
      (grossPurchaseAmount - discountAmount).clamp(0.0, double.infinity);

  double get totalGst =>
      taxType == PurchaseTaxType.gst ? taxableAmount * 0.03 : 0.0;
  double get cgst => totalGst / 2.0;
  double get sgst => totalGst / 2.0;
  double get grandTotal => taxableAmount + totalGst;

  double get cashPaid => _parseAmount(cashCtrl.text);
  double get upiPaid => _parseAmount(upiCtrl.text);
  double get cardPaid => _parseAmount(cardCtrl.text);
  double get totalPaid => cashPaid + upiPaid + cardPaid;
  double get balanceDue => grandTotal - totalPaid;

  Future<bool> savePurchase() async {
    if (_isSaving) {
      return false;
    }

    final enteredItems = items.where((item) => item.hasContent).toList();
    if (enteredItems.isEmpty) {
      _saveErrorMessage = 'Add at least one purchase item before saving.';
      notifyListeners();
      return false;
    }

    if (enteredItems.any((item) => !item.isValidEntry)) {
      _saveErrorMessage =
          'Complete every purchase line with a net weight and rate before saving.';
      notifyListeners();
      return false;
    }

    if (nameCtrl.text.trim().isEmpty) {
      _saveErrorMessage =
          'Enter or select a seller or supplier before saving this voucher.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final result = await _purchaseRepository.savePurchase(
        PurchaseVoucherDraft(
          sequenceNo: _purchaseNo,
          voucherNo: formattedPurchaseNo,
          source: purchaseSource,
          taxType: taxType,
          discountType: discountType,
          discountValue: discountValueInput,
          discountAmount: discountAmount,
          grossAmount: grossPurchaseAmount,
          taxableAmount: taxableAmount,
          gstAmount: totalGst,
          cgstAmount: cgst,
          sgstAmount: sgst,
          grandTotal: grandTotal,
          cashPaid: cashPaid,
          upiPaid: upiPaid,
          bankPaid: 0.0,
          cardPaid: cardPaid,
          totalPaid: totalPaid,
          balanceDue: balanceDue,
          party: PurchaseVoucherPartyDraft(
            customerId: selectedCustomer?.id,
            supplierId: selectedSupplier?.id,
            name: nameCtrl.text.trim(),
            mobile:
                mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
            city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
            panNumber: panCtrl.text.trim().isEmpty ? null : panCtrl.text.trim(),
            gstNumber: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          ),
          items: enteredItems
              .map(
                (item) => PurchaseVoucherItemDraft(
                  metal: item.metal,
                  description: item.descCtrl.text.trim(),
                  grossWeight: item.grossWt,
                  lessWeight: item.lessWt,
                  netWeight: item.netWt,
                  purity: item.purity,
                  fineWeight: item.fineWt,
                  rate: item.rate,
                  lineAmount: item.totalValue,
                ),
              )
              .toList(),
        ),
      );

      if (result == null) {
        _saveErrorMessage =
            'The purchase could not be saved. Please review the item details and try again.';
        return false;
      }

      _resetForm();
      await _syncNextPurchaseSequence();
      return true;
    } catch (error) {
      debugPrint('PurchaseEntryController.savePurchase: $error');
      _saveErrorMessage =
          'The purchase could not be saved. Please review the details and try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    for (final item in items) {
      item.removeListener(_notify);
      item.dispose();
    }
    items.clear();

    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    panCtrl.clear();
    gstCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    discountCtrl.clear();

    customerSuggestions = [];
    supplierSuggestions = [];
    selectedCustomer = null;
    selectedSupplier = null;
    counterpartNotFound = false;
    _saveErrorMessage = null;

    addItem();
  }

  double _parseAmount(String text) {
    if (text.trim().isEmpty) {
      return 0.0;
    }
    final normalized = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final item in items) {
      item.dispose();
    }
    mobileCtrl.dispose();
    nameCtrl.dispose();
    cityCtrl.dispose();
    panCtrl.dispose();
    gstCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    cardCtrl.dispose();
    discountCtrl.dispose();
    tableScrollCtrl.dispose();
    super.dispose();
  }
}
