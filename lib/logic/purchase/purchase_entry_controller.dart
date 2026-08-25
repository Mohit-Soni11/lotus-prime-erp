import 'dart:async';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import 'package:lotus_erp/database/db/app_database.dart';
import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../helpers/search/fuzzy_search_helper.dart';
import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../models/setting/metal_rate/metal_rate_model.dart';
import '../../repositories/purchase/purchase_entry_repository.dart';
import '../../repositories/setting/metal_rate/metal_rate_quote_service.dart';
import '../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../repositories/setting/shop_setup/shop_setup_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class PurchaseEntryController extends ChangeNotifier {
  PurchaseEntryController() {
    _init();
    _addPaymentListeners();
  }

  final AppDatabase _db = AppDatabase();
  late final PurchaseEntryRepository _purchaseRepository =
      PurchaseEntryRepository(db: _db);
  final ShopSetupRepository _shopRepository = ShopSetupRepository();
  final MetalRateQuoteService _rateQuoteService = MetalRateQuoteService();

  static const String sellerPayoutPendingMode = 'SELLER_PAYOUT_PENDING';
  static const String sellerPayoutExcessMode = 'SELLER_PAYOUT_EXCESS';

  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();

  final List<PurchaseItemModel> items = [];

  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();
  final TextEditingController payoutCommitmentDateCtrl =
      TextEditingController();

  final ScrollController tableScrollCtrl = ScrollController();

  List<CustomerListItemModel> customerSuggestions = [];
  CustomerListItemModel? selectedCustomer;
  bool counterpartNotFound = false;
  DateTime? payoutCommitmentDate;

  bool _isSaving = false;
  bool _disposed = false;
  String? _saveErrorMessage;
  int _purchaseNo = 1;
  String _voucherPrefix = 'AJ';

  bool get isSaving => _isSaving;
  String? get saveErrorMessage => _saveErrorMessage;
  String get formattedPurchaseNo =>
      '$_voucherPrefix-PUR-${DateTime.now().year}-${_purchaseNo.toString().padLeft(4, '0')}';

  PurchaseSource get purchaseSource => PurchaseSource.fromCustomer;

  bool get hasSelectedCounterparty => selectedCustomer != null;

  bool get canQuickCreateSeller {
    if (selectedCustomer != null) return false;
    final cleanMobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final hasName = nameCtrl.text.trim().isNotEmpty;
    final hasValidMobile = cleanMobile.length == 10;
    return hasName || hasValidMobile;
  }

  String? get selectedCounterpartyCaption {
    if (selectedCustomer != null) {
      return 'Linked seller profile';
    }
    return null;
  }

  Future<void> _init() async {
    await Future.wait([
      _syncVoucherPrefix(),
      _syncNextPurchaseSequence(),
    ]);
  }

  Future<void> _syncVoucherPrefix() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final shopData = await _shopRepository.fetchExistingSetup(tenantId);
      if (_disposed || shopData == null) {
        return;
      }

      final basicInfo = shopData['basic_info'] as Map<String, dynamic>?;
      final sourceName = [
        basicInfo?['brand_display_name'],
        basicInfo?['display_name'],
        basicInfo?['legal_name'],
      ]
          .map((value) => value?.toString().trim() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      final resolvedPrefix = _voucherPrefixFromShopName(sourceName);
      if (resolvedPrefix.isNotEmpty && resolvedPrefix != _voucherPrefix) {
        _voucherPrefix = resolvedPrefix;
        notifyListeners();
      }
    } catch (error) {
      AppLogger.debug('Purchase voucher prefix sync failed: $error');
    }
  }

  String _voucherPrefixFromShopName(String value) {
    final words = RegExp(r'[A-Za-z0-9]+')
        .allMatches(value.toUpperCase())
        .map((match) => match.group(0) ?? '')
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.length >= 2) {
      return words.take(4).map((word) => word[0]).join();
    }
    if (words.length == 1) {
      return words.single.substring(0, words.single.length.clamp(1, 3));
    }
    return _voucherPrefix;
  }

  Future<void> _syncNextPurchaseSequence() async {
    _purchaseNo = await _purchaseRepository.getNextSequence();
    notifyListeners();
  }

  void _addPaymentListeners() {
    cashCtrl.addListener(_notify);
    upiCtrl.addListener(_notify);
    cardCtrl.addListener(_notify);
  }

  void _notify() => notifyListeners();

  void addItem() {
    final item = PurchaseItemModel();
    item.addListener(_notify);
    items.add(item);
    notifyListeners();
    unawaited(applyPurchaseMasterBuyRate(item, force: true));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || item.isDisposed || !items.contains(item)) {
        return;
      }
      item.firstFieldFocus.requestFocus();
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
    FocusManager.instance.primaryFocus?.unfocus();
    final item = items.removeAt(index);
    item.removeListener(_notify);
    notifyListeners();
    _disposeItemAfterUnmount(item);
  }

  Future<void> applyPurchaseMasterBuyRate(
    PurchaseItemModel item, {
    bool force = false,
  }) async {
    final metalSnapshot = item.metal;
    final purityText = item.purityCtrl.text.trim();
    final purityPercent = item.purity;
    final quote = await _rateQuoteService.buyingQuote(
      metal: _rateMetalFromPurchase(metalSnapshot),
      purityLabel: purityText.isEmpty ? null : purityText,
      purityPercent: purityText.isEmpty ? null : purityPercent,
    );

    if (_disposed || item.isDisposed || !items.contains(item)) {
      return;
    }

    if (item.metal != metalSnapshot ||
        item.purityCtrl.text.trim() != purityText) {
      return;
    }

    if (quote == null || !quote.hasRate) {
      if (force) {
        item.clearMasterRateIfOwned();
      }
      return;
    }

    final changed = item.applyMasterRate(
      rate: quote.billingRate,
      sourceLabel: quote.rateSourceLabel,
      force: force,
    );
    if (changed) {
      notifyListeners();
    }
  }

  MetalRateMetal _rateMetalFromPurchase(PurchaseMetalType metal) {
    switch (metal) {
      case PurchaseMetalType.gold:
        return MetalRateMetal.gold;
      case PurchaseMetalType.silver:
        return MetalRateMetal.silver;
      case PurchaseMetalType.platinum:
        return MetalRateMetal.platinum;
      case PurchaseMetalType.diamond:
        return MetalRateMetal.diamond;
    }
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
              mobile: CustomerContactValue.displayMobile(row.mobile),
              city: _formatCustomerAddress(row),
              panNumber: row.panNumber ?? '',
              type: CustomerType.fromString(row.type),
              billCount: 0,
              createdAt: row.createdAt,
              initials: CustomerListItemModel.buildInitials(row.name),
            ),
          )
          .toList();
      counterpartNotFound = customerSuggestions.isEmpty;
    } catch (error) {
      AppLogger.debug('Purchase customer search failed: $error');
      customerSuggestions = [];
      counterpartNotFound = false;
    }
    notifyListeners();
  }

  Future<void> selectCustomer(CustomerListItemModel customer) async {
    selectedCustomer = customer;
    customerSuggestions = [];
    counterpartNotFound = false;

    final fullRow = await (_db.select(
      _db.customers,
    )..where((tbl) => tbl.id.equals(customer.id)))
        .getSingleOrNull();

    nameCtrl.text = customer.name;
    mobileCtrl.text = customer.mobile;
    cityCtrl.text =
        fullRow == null ? customer.city : _formatCustomerAddress(fullRow);
    panCtrl.text = _primaryIdentityNumber(fullRow);
    notifyListeners();
  }

  Future<bool> quickCreateSeller() async {
    final enteredName = nameCtrl.text.trim();
    final enteredMobile = mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final enteredAddress = cityCtrl.text.trim();
    final enteredIdentity = panCtrl.text.trim().toUpperCase();

    if (enteredName.isEmpty && enteredMobile.isEmpty) {
      return false;
    }
    if (enteredMobile.isNotEmpty && enteredMobile.length != 10) {
      return false;
    }

    try {
      if (enteredMobile.isNotEmpty) {
        final existing = await (_db.select(_db.customers)
              ..where((tbl) => tbl.mobile.equals(enteredMobile)))
            .getSingleOrNull();
        if (existing != null) {
          await selectCustomer(_customerListItemFromRow(existing));
          return true;
        }
      }

      final displayName = enteredName.isNotEmpty
          ? enteredName
          : 'Seller ${enteredMobile.substring(enteredMobile.length - 4)}';
      final identity = _sellerIdentityValues(enteredIdentity);
      final id = await _db.into(_db.customers).insert(
            CustomersCompanion(
              name: Value(displayName),
              firstName: Value(displayName),
              mobile: Value(CustomerContactValue.storageMobile(enteredMobile)),
              city: Value(enteredAddress.isEmpty ? null : enteredAddress),
              addressLine1:
                  Value(enteredAddress.isEmpty ? null : enteredAddress),
              panNumber: Value(identity.panNumber),
              idProofType: Value(identity.idProofType),
              idProofNumber: Value(identity.idProofNumber),
              type: const Value('Regular'),
              customerTier: const Value('Regular'),
              notes: const Value('Created from Customer Metal Purchase.'),
            ),
          );

      final row = await (_db.select(_db.customers)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      if (row == null) {
        return false;
      }

      await selectCustomer(_customerListItemFromRow(row));
      return true;
    } catch (error) {
      AppLogger.debug('PurchaseEntryController.quickCreateSeller: $error');
      return false;
    }
  }

  CustomerListItemModel _customerListItemFromRow(Customer row) {
    return CustomerListItemModel(
      id: row.id,
      name: row.name,
      mobile: CustomerContactValue.displayMobile(row.mobile),
      city: _formatCustomerAddress(row),
      panNumber: row.panNumber ?? '',
      type: CustomerType.fromString(row.type),
      billCount: 0,
      createdAt: row.createdAt,
      initials: CustomerListItemModel.buildInitials(row.name),
    );
  }

  _SellerIdentityValues _sellerIdentityValues(String value) {
    if (value.isEmpty) {
      return const _SellerIdentityValues();
    }
    final panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
    if (panPattern.hasMatch(value)) {
      return _SellerIdentityValues(panNumber: value);
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 12) {
      return _SellerIdentityValues(
        idProofType: 'Aadhaar',
        idProofNumber: digitsOnly,
      );
    }
    return _SellerIdentityValues(idProofNumber: value);
  }

  String _formatCustomerAddress(Customer customer) {
    return [
      customer.addressLine1,
      customer.addressLine2,
      customer.city,
      customer.state,
      customer.pincode,
      customer.country,
    ]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  String _primaryIdentityNumber(Customer? customer) {
    if (customer == null) {
      return '';
    }
    final pan = customer.panNumber?.trim().toUpperCase() ?? '';
    if (pan.isNotEmpty) {
      return pan;
    }
    return customer.idProofNumber?.trim().toUpperCase() ?? '';
  }

  void clearCounterpartySuggestions() {
    customerSuggestions = [];
    counterpartNotFound = false;
    notifyListeners();
  }

  void clearCounterpartySelection({bool clearFields = false}) {
    selectedCustomer = null;
    counterpartNotFound = false;
    if (clearFields) {
      mobileCtrl.clear();
      nameCtrl.clear();
      cityCtrl.clear();
      panCtrl.clear();
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

  double get discountValueInput => 0.0;
  double get discountAmount => 0.0;
  double get netPurchaseAmount => grossPurchaseAmount;

  double get grandTotal => netPurchaseAmount;

  double get cashPaid => _parseAmount(cashCtrl.text);
  double get upiPaid => _parseAmount(upiCtrl.text);
  double get cardPaid => _parseAmount(cardCtrl.text);
  double get totalPaid => cashPaid + upiPaid + cardPaid;
  double get balanceDue => grandTotal - totalPaid;
  bool get hasPendingSellerPayout => balanceDue > 0.005;
  bool get hasSellerPayoutExcess => balanceDue < -0.005;

  String? get invoiceReadinessError {
    final enteredItems = items.where((item) => item.hasContent).toList();
    if (enteredItems.isEmpty) {
      return 'Add at least one purchase item before generating invoice.';
    }
    if (enteredItems.any((item) => !item.isValidEntry)) {
      return 'Complete every purchase line with a net weight and rate before generating invoice.';
    }
    if (nameCtrl.text.trim().isEmpty) {
      return 'Enter or select the customer seller before generating invoice.';
    }
    if (totalPaid <= 0.005) {
      return 'Enter at least one seller payout amount before generating invoice.';
    }
    if (hasPendingSellerPayout && payoutCommitmentDate == null) {
      return 'Select payout commitment date for remaining seller payout.';
    }
    return null;
  }

  void setPayoutCommitmentDate(DateTime? date) {
    payoutCommitmentDate =
        date == null ? null : DateTime(date.year, date.month, date.day);
    payoutCommitmentDateCtrl.text = payoutCommitmentDate == null
        ? ''
        : formatDisplayDate(payoutCommitmentDate!);
    notifyListeners();
  }

  void clearPayoutCommitmentDate() => setPayoutCommitmentDate(null);

  static String formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

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
          'Enter or select the customer seller before saving this voucher.';
      notifyListeners();
      return false;
    }

    final readinessError = invoiceReadinessError;
    if (readinessError != null) {
      _saveErrorMessage = readinessError.replaceFirst(
        'generating invoice',
        'saving this voucher',
      );
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final pendingSellerPayout = hasPendingSellerPayout;
      final sellerPayoutExcess = hasSellerPayoutExcess;
      final result = await _purchaseRepository.savePurchase(
        PurchaseVoucherDraft(
          sequenceNo: _purchaseNo,
          voucherNo: formattedPurchaseNo,
          source: purchaseSource,
          taxType: PurchaseTaxType.normal,
          discountType: PurchaseDiscountType.flatAmount,
          discountValue: 0.0,
          discountAmount: 0.0,
          grossAmount: grossPurchaseAmount,
          taxableAmount: netPurchaseAmount,
          gstAmount: 0.0,
          cgstAmount: 0.0,
          sgstAmount: 0.0,
          grandTotal: grandTotal,
          cashPaid: cashPaid,
          upiPaid: upiPaid,
          bankPaid: 0.0,
          cardPaid: cardPaid,
          totalPaid: totalPaid,
          balanceDue: balanceDue,
          dueMode: pendingSellerPayout ? sellerPayoutPendingMode : null,
          excessMode: sellerPayoutExcess ? sellerPayoutExcessMode : null,
          promiseDate: pendingSellerPayout ? payoutCommitmentDate : null,
          paymentMeta: pendingSellerPayout
              ? 'Remaining seller payout scheduled by commitment date.'
              : null,
          party: PurchaseVoucherPartyDraft(
            customerId: selectedCustomer?.id,
            supplierId: null,
            name: nameCtrl.text.trim(),
            mobile:
                mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
            city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
            panNumber: panCtrl.text.trim().isEmpty ? null : panCtrl.text.trim(),
            gstNumber: null,
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
      AppLogger.debug('PurchaseEntryController.savePurchase: $error');
      _saveErrorMessage =
          'The purchase could not be saved. Please review the details and try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    final removedItems = List<PurchaseItemModel>.from(items);
    for (final item in removedItems) {
      item.removeListener(_notify);
    }
    items.clear();

    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    panCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    payoutCommitmentDateCtrl.clear();

    payoutCommitmentDate = null;
    customerSuggestions = [];
    selectedCustomer = null;
    counterpartNotFound = false;
    _saveErrorMessage = null;

    for (final item in removedItems) {
      _disposeItemAfterUnmount(item);
    }
  }

  void _disposeItemAfterUnmount(PurchaseItemModel item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!item.isDisposed) {
        item.dispose();
      }
    });
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
    FocusManager.instance.primaryFocus?.unfocus();
    for (final item in items) {
      item.removeListener(_notify);
      if (!item.isDisposed) {
        item.dispose();
      }
    }
    items.clear();
    mobileCtrl.dispose();
    nameCtrl.dispose();
    cityCtrl.dispose();
    panCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    cardCtrl.dispose();
    payoutCommitmentDateCtrl.dispose();
    tableScrollCtrl.dispose();
    super.dispose();
  }
}

class _SellerIdentityValues {
  final String? panNumber;
  final String? idProofType;
  final String? idProofNumber;

  const _SellerIdentityValues({
    this.panNumber,
    this.idProofType,
    this.idProofNumber,
  });
}
