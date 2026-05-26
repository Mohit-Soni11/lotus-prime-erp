import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_invoice_summary_logic.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_payment_controller.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../models/stock/stock_item_model/add_stock_gold/gold_item_model.dart';
import '../../../models/stock/supplier_model/supplier_model.dart';

class GoldStockController extends AddStockController {
  String _goldBatchCode;
  final AppDatabase _rateDb = AppDatabase();

  /// ✅ Payment controller — wired to this batch lifecycle
  final GoldPaymentController payment = GoldPaymentController();

  final TextEditingController supplierInvoiceNumberCtrl =
      TextEditingController();

  final List<GoldItemModel> _goldRows = [];

  String? _pendingGoldFocusId;
  String? _activeGoldRowId;
  SupplierLedgerSnapshot? _supplierLedger;
  String? _billPhotoPath;
  bool _isPickingBillPhoto = false;
  bool _isLoadingSupplierLedger = false;
  double _goldRatePer10g = 0.0;
  DateTime? _goldRateDate;
  bool _isLoadingGoldRate = false;

  GoldStockController()
      : _goldBatchCode = _generateGoldBatchCode(),
        super(initialMetal: StockCategory.gold) {
    payment.addListener(_handlePaymentChanged);
    _loadGoldRateSnapshot();
  }

  @override
  String get batchCode => _goldBatchCode;

  List<GoldItemModel> get goldRows => List.unmodifiable(_goldRows);

  List<GoldItemModel> get enteredGoldRows =>
      _goldRows.where((row) => row.hasAnyInput).toList(growable: false);

  SupplierLedgerSnapshot? get supplierLedger => _supplierLedger;
  double get supplierOutstandingDue => _supplierLedger?.outstandingDue ?? 0.0;
  bool get isLoadingSupplierLedger => _isLoadingSupplierLedger;
  String? get billPhotoPath => _billPhotoPath;
  String get billPhotoName =>
      _billPhotoPath == null ? '' : p.basename(_billPhotoPath!);
  bool get hasBillPhoto => _billPhotoPath != null && _billPhotoPath!.isNotEmpty;
  bool get isPickingBillPhoto => _isPickingBillPhoto;

  bool get isLoadingGoldRate => _isLoadingGoldRate;
  @override
  DateTime? get goldRateDate => _goldRateDate;
  double get goldRatePer10g => _goldRatePer10g;
  double get goldRatePerGram =>
      _goldRatePer10g > 0 ? _goldRatePer10g / 10.0 : 0.0;
  double get _activeInvoiceRatePerGram {
    final paymentRate = payment.todayRatePerGram;
    return paymentRate > 0 ? paymentRate : goldRatePerGram;
  }

  bool get hasGoldRateSnapshot => goldRatePerGram > 0;
  double get totalFineWeight => _roundGoldWeight(
        enteredGoldRows.fold(0.0, (sum, row) => sum + row.fineWeight),
      );
  double get totalMakingAmount =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.makingAmount);
  GoldPaymentSnapshot get paymentSnapshot {
    payment.updateInvoiceSummary(
      fine: totalFineWeight,
      making: totalMakingAmount,
      notify: false,
    );
    payment.syncGstEnabled(gstEnabled, notify: false);

    return GoldPaymentSnapshot(
      paymentMode: payment.paymentMode,
      settlementPreference: payment.metalDueReturnType,
      discountMode: payment.discountMode,
      ratePer10g: payment.todayRatePer10g,
      ratePerGram: payment.todayRatePerGram,
      grossFineWeight: payment.grossFineFromItems,
      payableFineWeight: payment.totalFineFromItems,
      fineDiscountWeight: payment.fineDiscountWeight,
      cashDiscountAmount: payment.cashDiscountAmount,
      fineValueAmount: payment.fineValueAmount,
      totalMakingAmount: payment.totalMakingFromItems,
      subtotalAmount: payment.subTotalAmount,
      gstPercent: payment.taxPercentage,
      appliedGstAmount: payment.taxAmount,
      totalBillAmount: payment.finalBillAmount,
      cashPaid: payment.cashPaid,
      upiPaid: payment.upiPaid,
      bankingPaid: payment.bankPaid,
      cardPaid: payment.cardPaid,
      cashBankPaidTotal: payment.cashBankPaidTotal,
      totalPaidValue: payment.totalPaidValue,
      dueAmount: payment.dueAmount,
      returnAmount: payment.returnAmount,
      hasDue: payment.hasDue,
      hasReturn: payment.hasReturn,
      isSettled: payment.isSettled,
      metalGrossWeight: payment.metalGivenWeight,
      metalPurity: payment.metalGivenPurity,
      metalFineCalculated: payment.fineReceived,
      metalPaidValue: payment.metalReceivedValue,
      metalFineShortage: payment.fineShortage,
      metalFineExcess: payment.fineExcess,
      metalFineShortageValue: payment.fineShortageValue,
      metalFineExcessValue: payment.fineExcessValue,
      metalFineEquivalentCash: payment.differenceInCashValue,
      cashTargetAmount: payment.cashTargetAmount,
      previousSupplierDue: payment.supplierPreviousDue,
      previousSupplierDueAdjustment: payment.previousDueAdjustment,
      previousSupplierDueFineEquivalent: payment.previousDueFineEquivalent,
      balanceLabel: payment.balanceLabel,
    );
  }

  @override
  void setPurity(String option) {
    final previousDefault = _defaultGoldPurityLabel();
    super.setPurity(option);
    _syncGoldRowsWithBatchPurity(previousDefault);
    _loadGoldRateSnapshot();
  }

  @override
  void setCustomPurity(String value) {
    final previousDefault = _defaultGoldPurityLabel();
    super.setCustomPurity(value);
    _syncGoldRowsWithBatchPurity(previousDefault);
    _loadGoldRateSnapshot();
  }

  GoldInvoiceSummaryData get invoiceSummary =>
      GoldInvoiceSummaryData.fromController(this);

  @override
  int get totalQuantity =>
      enteredGoldRows.fold(0, (sum, row) => sum + row.pieces);

  String get goldRateDisplay {
    if (_isLoadingGoldRate) {
      return 'Loading rate...';
    }
    if (!hasGoldRateSnapshot) {
      return 'Rate missing';
    }
    return 'Rs ${goldRatePerGram.toStringAsFixed(2)}/g';
  }

  @override
  void setSessionSupplier(SupplierListItemModel? supplier) {
    super.setSessionSupplier(supplier);
    _loadSupplierLedger(supplier?.id);
  }

  @override
  void setSessionSupplierText(String value) {
    super.setSessionSupplierText(value);
    _clearSupplierLedger();
  }

  @override
  void clearSessionSupplier({bool clearFields = true}) {
    super.clearSessionSupplier(clearFields: clearFields);
    _clearSupplierLedger();
  }

  Future<void> pickBillPhoto() async {
    if (_isPickingBillPhoto) {
      return;
    }

    _isPickingBillPhoto = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final sourcePath = result?.files.single.path;
      if (sourcePath == null || sourcePath.trim().isEmpty) {
        return;
      }

      final source = File(sourcePath);
      final docDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(
        p.join(docDir.path, 'lotus_erp', 'supplier_bills'),
      );
      await targetDir.create(recursive: true);
      final extension =
          p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
      final fileName =
          '${batchCode}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final target = File(p.join(targetDir.path, fileName));
      final copied = await source.copy(target.path);
      _billPhotoPath = copied.path;
    } finally {
      _isPickingBillPhoto = false;
      notifyListeners();
    }
  }

  void clearBillPhoto() {
    _billPhotoPath = null;
    notifyListeners();
  }

  Future<void> _loadSupplierLedger(int? supplierId) async {
    if (supplierId == null) {
      _clearSupplierLedger();
      return;
    }

    _isLoadingSupplierLedger = true;
    notifyListeners();

    try {
      final repo = SupplierRepository(_rateDb);
      final ledger = await repo.getLedgerSnapshot(supplierId);
      if (linkedSupplier?.id != supplierId && sessionSupplierId != supplierId) {
        return;
      }
      _supplierLedger = ledger;
      payment.setSupplierPreviousDue(ledger.outstandingDue);
    } catch (_) {
      _supplierLedger = null;
      payment.setSupplierPreviousDue(0.0);
    } finally {
      _isLoadingSupplierLedger = false;
      notifyListeners();
    }
  }

  void _clearSupplierLedger() {
    _supplierLedger = null;
    _isLoadingSupplierLedger = false;
    payment.setSupplierPreviousDue(0.0);
    notifyListeners();
  }

  @override
  List<StockRowEntry> get enteredRows {
    final supplierId = linkedSupplier?.id;
    final supplierName = supplierDisplayName;

    return enteredGoldRows.map((rowModel) {
      final pieces = rowModel.pieces;
      final lotDivisor = pieces > 0 ? pieces : 1;
      final row = StockRowEntry(id: rowModel.id, hsnCode: defaultHsnCode);
      row.itemName = rowModel.itemName;
      row.description = rowModel.categoryLabel;
      row.subCategory = _mapGoldSubCategory(rowModel.categoryLabel);
      row.subCategoryLabel = rowModel.categoryLabel;
      row.huid = rowModel.huid;
      row.grossWeight = rowModel.grossWeight / lotDivisor;
      row.stoneWeight = rowModel.lessWeight / lotDivisor;
      row.touchPercent = rowModel.effectiveTotalPurityPercent;
      row.purityLabel = rowModel.purityLabel;
      row.purchaseRate = rowModel.purchaseRate;
      row.purchasePriceOverride = rowModel.totalAmount / lotDivisor;
      row.makingCharges = switch (rowModel.makingChargesType) {
        MakingChargesType.flat => rowModel.makingValue / lotDivisor,
        MakingChargesType.perGram ||
        MakingChargesType.percent =>
          rowModel.makingValue,
      };
      row.makingChargesType = rowModel.makingChargesType;
      row.gstRate = gstEnabled ? gstRate : 0.0;
      row.supplierId = supplierId;
      row.supplierName = supplierName;
      row.quantity = pieces;
      return row;
    }).toList(growable: false);
  }

  @override
  int get enteredRowCount => enteredGoldRows.length;

  @override
  int get rowCount => _goldRows.length;

  @override
  double get totalGrossWeight =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.grossWeight);

  @override
  double get totalNetWeight =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.netWeight);

  @override
  double get totalEstimatedCost =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalEstimatedSelling =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalTaxableAmount =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalGstAmount =>
      gstEnabled ? totalTaxableAmount * (gstRate / 100.0) : 0.0;

  @override
  double get cgstAmount => totalGstAmount / 2.0;

  @override
  double get sgstAmount => totalGstAmount / 2.0;

  @override
  double get totalBatchAmount => totalTaxableAmount + totalGstAmount;

  @override
  double get totalFineGold => totalFineWeight;

  @override
  int get rowsWithErrorsCount =>
      enteredGoldRows.where((row) => validateGoldRow(row) != null).length;

  @override
  bool get hasAnyInput => super.hasAnyInput || enteredGoldRows.isNotEmpty;

  String? validateGoldRow(GoldItemModel row) {
    if (!row.hasAnyInput) {
      return null;
    }
    if (row.categoryLabel.isEmpty) {
      return 'Category is required';
    }
    if (row.itemName.isEmpty) {
      return 'Item name is required';
    }
    if (row.itemName.length < 2) {
      return 'Item name must be at least 2 characters';
    }
    if (row.pieces < 1) {
      return 'Pieces must be at least 1';
    }
    if (row.grossWeight <= 0) {
      return 'Gross weight must be greater than 0';
    }
    if (row.lessWeight < 0) {
      return 'Less weight cannot be negative';
    }
    if (row.lessWeight > row.grossWeight) {
      return 'Less weight cannot exceed gross weight';
    }
    if (row.purityLabel.isEmpty) {
      return 'Base purity is required';
    }
    if (row.effectiveTotalPurityPercent <= 0 ||
        row.effectiveTotalPurityPercent > 100) {
      return 'Total purity must be between 0 and 100';
    }
    if (row.purchaseRate <= 0) {
      return 'Gold daily rate is missing. Update Gold jewellery rate first.';
    }
    if (row.makingValue < 0) {
      return 'Making charge cannot be negative';
    }
    if (row.huid.isNotEmpty && row.huid.length != 6) {
      return 'HUID must be exactly 6 characters';
    }
    return null;
  }

  @override
  Future<String?> validateCustomBatch(List<StockRowEntry> rowsToSave) async {
    if (rowsToSave.isEmpty) {
      return null;
    }
    if (payment.todayRatePer10g <= 0) {
      return 'Enter the Gold invoice rate before saving this batch.';
    }
    return null;
  }

  @override
  Future<PurchaseVoucherDraft?> buildPurchaseVoucherDraft(
    List<StockRowEntry> rowsToSave,
  ) async {
    if (rowsToSave.isEmpty) {
      return null;
    }

    final snapshot = paymentSnapshot;
    final sequenceNo = await getNextPurchaseSequence();
    final supplierName = supplierDisplayName.trim().isNotEmpty
        ? supplierDisplayName.trim()
        : supplierNameCtrl.text.trim();

    return PurchaseVoucherDraft(
      sequenceNo: sequenceNo,
      voucherNo:
          'GSTOCK-${DateTime.now().year}-${sequenceNo.toString().padLeft(4, '0')}',
      supplierInvoiceNo: supplierInvoiceNumberCtrl.text.trim().isEmpty
          ? null
          : supplierInvoiceNumberCtrl.text.trim(),
      source: PurchaseSource.fromSupplier,
      taxType: gstEnabled ? PurchaseTaxType.gst : PurchaseTaxType.normal,
      discountType: PurchaseDiscountType.flatAmount,
      discountValue: 0.0,
      discountAmount: 0.0,
      grossAmount: invoiceSummary.itemSnapshotAmount,
      taxableAmount: snapshot.subtotalAmount,
      gstAmount: snapshot.appliedGstAmount,
      cgstAmount: gstEnabled ? snapshot.appliedGstAmount / 2.0 : 0.0,
      sgstAmount: gstEnabled ? snapshot.appliedGstAmount / 2.0 : 0.0,
      grandTotal: snapshot.totalBillAmount,
      cashPaid: snapshot.cashPaid,
      upiPaid: snapshot.upiPaid,
      bankPaid: snapshot.bankingPaid,
      cardPaid: snapshot.cardPaid,
      totalPaid: snapshot.totalPaidValue,
      balanceDue: snapshot.dueAmount,
      // Legacy purchase schema stores the Gold 24K/10g invoice rate in this
      // field name. UI and calculation code use ratePer10g/ratePerGram.
      ratePerKg: snapshot.ratePer10g,
      metalPaidGrossWeight: snapshot.metalGrossWeight,
      metalPaidPurity: snapshot.metalPurity,
      metalPaidFine: snapshot.metalFineCalculated,
      metalPaidValue: snapshot.metalPaidValue,
      dueMode: snapshot.hasDue ? snapshot.settlementPreference.name : null,
      excessMode:
          snapshot.hasReturn ? snapshot.settlementPreference.name : null,
      promiseDate: snapshot.hasDue ? payment.promiseDate : null,
      paymentMeta: jsonEncode({
        'mode': snapshot.paymentMode.name,
        'taxMode': payment.taxMode.name,
        'discountMode': payment.discountMode.name,
        'fineDiscountWeight': snapshot.fineDiscountWeight,
        'cashDiscountAmount': snapshot.cashDiscountAmount,
        'gstRatePercent': snapshot.gstPercent,
        'metalGstPercent': payment.metalGstPercent,
        'cashGstPercent': payment.cashGstPercent,
        'settlementPreference': snapshot.settlementPreference.name,
        'promiseDate':
            snapshot.hasDue ? payment.promiseDate?.toIso8601String() : null,
        'cashBankPaidTotal': snapshot.cashBankPaidTotal,
        'cashTargetAmount': snapshot.cashTargetAmount,
        'metalFineShortage': snapshot.metalFineShortage,
        'metalFineExcess': snapshot.metalFineExcess,
        'metalFineShortageValue': snapshot.metalFineShortageValue,
        'metalFineExcessValue': snapshot.metalFineExcessValue,
        'balanceLabel': snapshot.balanceLabel,
        'billPhotoPath': _billPhotoPath,
        'oldDueBefore': snapshot.previousSupplierDue,
        'oldDueAdjustedAmount': snapshot.previousSupplierDueAdjustment,
        'oldDueFineEquivalent': snapshot.previousSupplierDueFineEquivalent,
        'metalLines': payment.metalLinePayloads,
      }),
      party: PurchaseVoucherPartyDraft(
        supplierId: linkedSupplier?.id ?? sessionSupplierId,
        name: supplierName.isEmpty ? 'Walk-in Supplier' : supplierName,
        mobile: supplierMobileCtrl.text.trim().isEmpty
            ? null
            : supplierMobileCtrl.text.trim(),
        city: supplierRegionCtrl.text.trim().isEmpty
            ? null
            : supplierRegionCtrl.text.trim(),
        panNumber: supplierPanCtrl.text.trim().isEmpty
            ? null
            : supplierPanCtrl.text.trim(),
        gstNumber: supplierGstCtrl.text.trim().isEmpty
            ? null
            : supplierGstCtrl.text.trim(),
        contactName: linkedSupplier?.contactPersonName,
      ),
      items: rowsToSave
          .map(
            (row) => PurchaseVoucherItemDraft(
              metal: PurchaseMetalType.gold,
              description: row.itemName.trim(),
              quantity: row.quantity,
              grossWeight: row.grossWeight,
              lessWeight: row.lessWeight,
              netWeight: row.netWeight,
              purity: row.resolveTouch(selectedPurityBasePercent),
              fineWeight: _roundGoldWeight(
                row.fineWeight(selectedPurityBasePercent),
              ),
              rate: snapshot.ratePerGram > 0
                  ? snapshot.ratePerGram
                  : row.purchaseRate,
              lineAmount: row.totalCostValue,
              subCategory: row.subCategoryLabel.trim().isEmpty
                  ? row.subCategory.label
                  : row.subCategoryLabel.trim(),
              huid: row.huid.trim().isEmpty
                  ? null
                  : row.huid.trim().toUpperCase(),
              hsnCode: row.hsnCode.trim().isEmpty
                  ? defaultHsnCode
                  : row.hsnCode.trim(),
              labourCharge: row.makingCharges,
              labourType: row.makingChargesType,
              purityLabel: resolvedPurityStorageLabel(row),
              effectiveRatePerGram: snapshot.ratePerGram > 0
                  ? snapshot.ratePerGram
                  : row.purchaseRate,
              gstRate: gstEnabled ? gstRate : 0.0,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  String buildPurchaseSuccessMessage(
    PurchaseSaveResult result,
    List<StockRowEntry> rowsToSave,
  ) {
    return '${rowsToSave.length} Gold row${rowsToSave.length == 1 ? '' : 's'} saved under voucher ${result.voucherNo}. Payment split and supplier settlement have been linked to this batch.';
  }

  @override
  void addRow({bool requestFocus = false}) {
    _addGoldModel(requestFocus: requestFocus);
  }

  void _addGoldModel({bool requestFocus = false}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = GoldItemModel(
      id: id,
      initialPurityLabel: _defaultGoldPurityLabel(),
      initialWastagePercent: 0.0,
      initialPurchaseRate: _activeInvoiceRatePerGram,
      initialPieces: 1,
    );
    model.addListener(notifyListeners);
    _goldRows.add(model);
    if (requestFocus) {
      _pendingGoldFocusId = id;
    }
    notifyListeners();
  }

  @override
  void removeRow(String rowId) {
    final index = _goldRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    final model = _goldRows[index];
    model.removeListener(notifyListeners);
    _goldRows.removeAt(index);

    if (_activeGoldRowId == rowId) {
      _activeGoldRowId = _goldRows.isNotEmpty ? _goldRows.last.id : null;
    }
    if (_pendingGoldFocusId == rowId) {
      _pendingGoldFocusId = null;
    }

    model.disposeAll();
    notifyListeners();
  }

  @override
  void removeActiveRow() {
    if (_goldRows.isEmpty) {
      return;
    }
    final targetId = _activeGoldRowId != null &&
            _goldRows.any((row) => row.id == _activeGoldRowId)
        ? _activeGoldRowId!
        : _goldRows.last.id;
    removeRow(targetId);
  }

  void setGoldActiveRow(String id) => _activeGoldRowId = id;

  bool shouldRequestGoldFocus(String id) => _pendingGoldFocusId == id;

  void clearGoldFocusRequest(String id) {
    if (_pendingGoldFocusId == id) {
      _pendingGoldFocusId = null;
    }
  }

  void _handlePaymentChanged() {
    if (!_syncGoldRowRatesWithPayment()) {
      notifyListeners();
    }
  }

  bool _syncGoldRowRatesWithPayment() {
    final ratePerGram = payment.todayRatePerGram;
    if (ratePerGram <= 0) {
      return false;
    }

    var changed = false;
    for (final row in _goldRows) {
      changed =
          row.applyPurchaseRate(ratePerGram, onlyIfEmpty: false) || changed;
    }
    return changed;
  }

  void _syncGoldRowsWithBatchPurity(String previousDefault) {
    final nextDefault = _defaultGoldPurityLabel();
    if (nextDefault.trim().isEmpty) {
      return;
    }

    for (final row in _goldRows) {
      final current = row.purityLabel;
      if (current.isEmpty || current == previousDefault) {
        row.applyPurityDefaults(
          nextDefault,
          wastagePercent: 0.0,
          overwriteWhenBlank: false,
        );
      }
    }
  }

  void completeRowAndAdvanceGold(String rowId) {
    final index = _goldRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    for (var i = index + 1; i < _goldRows.length; i++) {
      if (!_goldRows[i].hasAnyInput) {
        _pendingGoldFocusId = _goldRows[i].id;
        notifyListeners();
        return;
      }
    }

    _addGoldModel(requestFocus: true);
  }

  @override
  void resetAllRows() {
    _clearGoldRows();
    notifyListeners();
  }

  @override
  void resetForNewBatch() {
    _goldBatchCode = _generateGoldBatchCode();
    supplierInvoiceNumberCtrl.clear();
    _billPhotoPath = null;
    _supplierLedger = null;
    _isLoadingSupplierLedger = false;
    payment.resetSettlement();
    _clearGoldRows();
    super.resetForNewBatch();
    _loadGoldRateSnapshot();
  }

  void _clearGoldRows() {
    for (final row in _goldRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _goldRows.clear();
    _pendingGoldFocusId = null;
    _activeGoldRowId = null;
  }

  @override
  void dispose() {
    supplierInvoiceNumberCtrl.dispose();
    payment.removeListener(_handlePaymentChanged);
    payment.dispose();
    for (final row in _goldRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _goldRows.clear();
    super.dispose();
  }

  Future<void> _loadGoldRateSnapshot() async {
    _isLoadingGoldRate = true;
    notifyListeners();

    try {
      final masterProfile =
          await MetalRateRepository().loadProfile(MetalRateMetal.gold);
      final latestRate = await (_rateDb.select(_rateDb.dailyRates)
            ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
            ..limit(1))
          .getSingleOrNull();
      final masterRate = _gold24kMarketRatePer10g(masterProfile);
      final latest24kRate =
          latestRate == null ? 0.0 : _parseGoldRate(latestRate.gold24k);

      if (masterRate > 0) {
        _goldRatePer10g = masterRate;
        _goldRateDate = masterProfile.updatedAt;
      } else if (latest24kRate > 0) {
        _goldRatePer10g = latest24kRate;
        _goldRateDate = latestRate!.rateDate;
      } else {
        _goldRatePer10g = 0.0;
        _goldRateDate = null;
      }

      payment.setTodayRatePer10g(_goldRatePer10g);

      for (final row in _goldRows) {
        row.applyPurchaseRate(_activeInvoiceRatePerGram, onlyIfEmpty: false);
      }
    } catch (_) {
      _goldRatePer10g = 0.0;
      _goldRateDate = null;
    }

    _isLoadingGoldRate = false;
    notifyListeners();
  }

  String _defaultGoldPurityLabel() {
    final trimmed = purityDisplay.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return '22K';
    }
    final karatMatch = RegExp(r'\b(24|22|18|14|9)\s*K\b').firstMatch(trimmed);
    if (karatMatch != null) {
      return '${karatMatch.group(1)!}K';
    }
    final hallmarkMatch =
        RegExp(r'\b(999|916|750|585|375)\b').firstMatch(trimmed);
    if (hallmarkMatch != null) {
      return hallmarkMatch.group(1)!;
    }
    return trimmed;
  }

  String _normaliseGoldRateKey(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      return '22K';
    }
    final karatMatch =
        RegExp(r'\b(24|22|18|14|9)\s*K\b').firstMatch(normalized);
    if (karatMatch != null) {
      return '${karatMatch.group(1)!}K';
    }
    final hallmarkMatch =
        RegExp(r'\b(999|916|750|585|375)\b').firstMatch(normalized);
    if (hallmarkMatch != null) {
      return switch (hallmarkMatch.group(1)!) {
        '999' => '24K',
        '916' => '22K',
        '750' => '18K',
        '585' => '14K',
        '375' => '9K',
        _ => normalized,
      };
    }
    final percentMatch =
        RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%').firstMatch(normalized);
    if (percentMatch != null) {
      final percent = double.tryParse(percentMatch.group(1) ?? '');
      if (percent != null) {
        if (percent >= 99.5) return '24K';
        if ((percent - 91.6).abs() <= 0.4) return '22K';
        if ((percent - 75.0).abs() <= 0.4) return '18K';
        if ((percent - 58.5).abs() <= 0.4) return '14K';
        if ((percent - 37.5).abs() <= 0.4) return '9K';
        return percent.toStringAsFixed(2);
      }
    }
    return normalized.replaceAll(' ', '');
  }

  double _gold24kMarketRatePer10g(MetalRateProfile profile) {
    if (profile.physicalMarketRatePer10g > 0) {
      return profile.physicalMarketRatePer10g;
    }

    for (final plan in profile.purityPlans) {
      if (_normaliseGoldRateKey(plan.label) == '24K' &&
          plan.manualDisplayRatePer10g > 0) {
        return plan.manualDisplayRatePer10g;
      }
    }

    if (profile.marketRatePer10g > 0) {
      return profile.marketRatePer10g;
    }
    if (profile.mcxRatePer10g > 0) {
      return profile.mcxRatePer10g;
    }
    return profile.marketBaseRatePer10g;
  }

  StockSubCategory _mapGoldSubCategory(String categoryLabel) {
    final normalized = categoryLabel.trim().toLowerCase();
    if (normalized.contains('anklet') || normalized.contains('payal')) {
      return StockSubCategory.anklet;
    }
    if (normalized.contains('chain')) {
      return StockSubCategory.chain;
    }
    if (normalized.contains('bracelet')) {
      return StockSubCategory.bracelet;
    }
    if (normalized.contains('bichhiya') || normalized.contains('toe ring')) {
      return StockSubCategory.ring;
    }
    if (normalized.contains('ring')) {
      return StockSubCategory.ring;
    }
    if (normalized.contains('bangle') || normalized.contains('kada')) {
      return StockSubCategory.bangle;
    }
    if (normalized.contains('pendant') || normalized.contains('locket')) {
      return StockSubCategory.pendant;
    }
    if (normalized.contains('necklace') || normalized.contains('set')) {
      return StockSubCategory.necklace;
    }
    if (normalized.contains('earring') || normalized.contains('jhumka')) {
      return StockSubCategory.earring;
    }
    return StockSubCategory.other;
  }

  double _parseGoldRate(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  double _roundGoldWeight(double value) {
    if (value <= 0) {
      return 0.0;
    }
    return (value * 1000).roundToDouble() / 1000.0;
  }

  static String _generateGoldBatchCode() {
    final now = DateTime.now();
    final datePart = '${now.year.toString().substring(2)}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final timePart = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'GOL-$datePart-$timePart';
  }
}
