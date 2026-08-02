import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_batch_code_generator.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_invoice_summary_logic.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_payment_controller.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_supplier_invoice_policy.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_batch_posting_guard.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_bill_attachment_service.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_ledger_loader.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';

import 'package:lotus_erp/features/stock/silver/domain/models/silver_item_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';

enum SilverIntakeMode { singleGrade, mixedInvoice }

class SilverStockController extends AddStockController {
  String _silverBatchCode = '';
  DateTime _silverBatchCreatedAt = DateTime.now();
  final AppDatabase _rateDb = AppDatabase();
  late final SilverBatchCodeGenerator _batchCodeGenerator =
      SilverBatchCodeGenerator(_rateDb);
  late final SilverSupplierInvoicePolicy _supplierInvoicePolicy =
      SilverSupplierInvoicePolicy(_rateDb);

  final SilverPaymentController payment = SilverPaymentController();

  final TextEditingController supplierInvoiceNumberCtrl =
      TextEditingController();

  final List<SilverItemModel> _silverRows = [];

  String? _pendingSilverFocusId;
  String? _activeSilverRowId;
  SupplierLedgerSnapshot? _supplierLedger;
  String? _billPhotoPath;
  bool _isPickingBillPhoto = false;
  bool _isLoadingSupplierLedger = false;
  double _silverRatePer10g = 0.0;
  DateTime? _silverRateDate;
  bool _isLoadingSilverRate = false;
  bool _roundOffInvoiceFine = false;
  bool _isLoadingBatchCode = false;
  bool _currentBatchPosted = false;
  SilverIntakeMode _intakeMode = SilverIntakeMode.singleGrade;

  SilverStockController() : super(initialMetal: StockCategory.silver) {
    payment.addListener(_syncPurchaseValuationRateToRows);
    _startNewBatchIdentity(notify: false);
    _loadSilverRateSnapshot();
  }

  @override
  String get batchCode => _silverBatchCode;

  DateTime get batchCreatedAt => _silverBatchCreatedAt;
  bool get isLoadingBatchCode => _isLoadingBatchCode;
  bool get isCurrentBatchPosted => _currentBatchPosted;
  SilverIntakeMode get intakeMode => _intakeMode;
  bool get isMixedInvoiceMode => _intakeMode == SilverIntakeMode.mixedInvoice;
  String get intakeModeTitle =>
      isMixedInvoiceMode ? 'Mixed Silver Supplier Invoice' : purityDisplay;

  List<SilverItemModel> get silverRows => List.unmodifiable(_silverRows);

  List<SilverItemModel> get enteredSilverRows =>
      _silverRows.where((row) => row.hasAnyInput).toList(growable: false);

  SupplierLedgerSnapshot? get supplierLedger => _supplierLedger;
  double get supplierOutstandingDue => _supplierLedger?.outstandingDue ?? 0.0;
  bool get isLoadingSupplierLedger => _isLoadingSupplierLedger;
  String? get billPhotoPath => _billPhotoPath;
  String get billPhotoName =>
      SupplierBillAttachmentService.fileName(_billPhotoPath);
  bool get hasBillPhoto => _billPhotoPath != null && _billPhotoPath!.isNotEmpty;
  bool get isPickingBillPhoto => _isPickingBillPhoto;

  bool get isLoadingSilverRate => _isLoadingSilverRate;
  DateTime? get silverRateDate => _silverRateDate;
  double get silverRatePer10g => _silverRatePer10g;
  double get silverRatePerGram =>
      _silverRatePer10g > 0 ? _silverRatePer10g / 10.0 : 0.0;
  bool get hasSilverRateSnapshot => silverRatePerGram > 0;
  double get totalFineWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.fineWeight);

  double get totalActualFineWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.actualFineWeight);

  double get totalValuationFineWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.valuationFineWeight);
  double get totalMakingAmount =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.makingAmount);
  bool get canRoundOffInvoiceFine =>
      enteredSilverRows.any((row) => row.hasFractionalFineWeight);

  SilverPaymentSnapshot get paymentSnapshot {
    payment.updateInvoiceSummary(
      fine: totalFineWeight,
      making: totalMakingAmount,
      notify: false,
    );
    payment.syncGstEnabled(gstEnabled, notify: false);

    return SilverPaymentSnapshot(
      paymentMode: payment.paymentMode,
      settlementPreference: payment.metalDueReturnType,
      discountMode: payment.discountMode,
      ratePerKg: payment.todayRatePerKg,
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
    _intakeMode = SilverIntakeMode.singleGrade;
    super.setPurity(option);
    _loadSilverRateSnapshot();
  }

  @override
  void setCustomPurity(String value) {
    _intakeMode = SilverIntakeMode.singleGrade;
    super.setCustomPurity(value);
    _loadSilverRateSnapshot();
  }

  void startMixedSupplierInvoice() {
    _intakeMode = SilverIntakeMode.mixedInvoice;
    super.setCustomPurity('Mixed Silver Supplier Invoice');
    _loadSilverRateSnapshot();
  }

  SilverInvoiceSummaryData get invoiceSummary =>
      SilverInvoiceSummaryData.fromController(this);

  @override
  int get totalQuantity =>
      enteredSilverRows.fold(0, (sum, row) => sum + row.pieces);

  String get silverRateDisplay {
    if (_isLoadingSilverRate) {
      return 'Loading rate...';
    }
    if (!hasSilverRateSnapshot) {
      return 'Rate missing';
    }
    return 'Rs ${silverRatePerGram.toStringAsFixed(2)}/g';
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
      final copiedPath = await SupplierBillAttachmentService.pickAndCopy(
        batchCode: batchCode,
        mode: SupplierBillAttachmentMode.imageOnly,
      );
      if (copiedPath != null) {
        _billPhotoPath = copiedPath;
      }
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
      final ledger = await SupplierLedgerLoader.load(
        db: _rateDb,
        supplierId: supplierId,
      );
      if (linkedSupplier?.id != supplierId && sessionSupplierId != supplierId) {
        return;
      }
      _supplierLedger = ledger;
      payment.setSupplierPreviousDue(ledger?.outstandingDue ?? 0.0);
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

    return enteredSilverRows.map((rowModel) {
      final stockUnits =
          rowModel.enteredQuantity > 0 ? rowModel.enteredQuantity : 1;
      final lotDivisor = stockUnits;
      final huids =
          rowModel.huidTrackingEnabled ? rowModel.huidValues : <String>[];
      final row = StockRowEntry(id: rowModel.id, hsnCode: defaultHsnCode);
      row.itemName = rowModel.itemName;
      row.description = rowModel.categoryLabel;
      row.companyLabel = rowModel.companyLabel.isEmpty
          ? 'Local / Unbranded'
          : rowModel.companyLabel;
      row.segmentLabel = rowModel.segmentLabel;
      row.subCategory = _mapSilverSubCategory(rowModel.categoryLabel);
      row.subCategoryLabel = rowModel.categoryLabel;
      row.huids = huids;
      row.huid = huids.isEmpty ? '' : huids.first;
      row.grossWeight = rowModel.grossWeight;
      row.stoneWeight = rowModel.lessWeight;
      row.touchPercent = rowModel.basePurityPercent;
      row.wastageFineWeight =
          rowModel.valuationFineWeight - rowModel.actualFineWeight;
      row.valuationFineWeight = rowModel.valuationFineWeight;
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
      row.quantity = stockUnits;
      row.quantityMode = rowModel.quantityModeCode;
      row.packetCount = rowModel.packetCount;
      row.piecesPerPacket = rowModel.piecesPerPacket;
      return row;
    }).toList(growable: false);
  }

  @override
  int get enteredRowCount => enteredSilverRows.length;

  @override
  int get rowCount => _silverRows.length;

  @override
  double get totalGrossWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.grossWeight);

  @override
  double get totalNetWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.netWeight);

  @override
  double get totalEstimatedCost =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalEstimatedSelling =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalTaxableAmount =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

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
  double get totalFineGold => 0.0;

  @override
  int get rowsWithErrorsCount =>
      enteredSilverRows.where((row) => validateSilverRow(row) != null).length;

  @override
  bool get hasAnyInput => super.hasAnyInput || enteredSilverRows.isNotEmpty;

  String? validateSilverRow(SilverItemModel row) {
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
    if (row.enteredQuantity < 1) {
      return '${row.quantityMode.label} count must be at least 1';
    }
    if (row.quantityMode == SilverQuantityMode.packet &&
        row.piecesPerPacket < 1) {
      return 'Pieces per packet must be at least 1';
    }
    if (row.pieces < 1) {
      return 'Total pieces must be at least 1';
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
    if (!isMixedInvoiceMode && selectedPurityBasePercent > 0) {
      final variance =
          (row.basePurityPercent - selectedPurityBasePercent).abs();
      if (variance > 0.2) {
        return 'Row purity must match the selected silver grade';
      }
    }
    if (row.effectiveTotalPurityPercent <= 0 ||
        row.effectiveTotalPurityPercent > 100) {
      return 'Total purity must be between 0 and 100';
    }
    if (row.purchaseRate <= 0) {
      return 'Silver daily rate is missing. Update silver jewellery rate first.';
    }
    if (row.makingValue < 0) {
      return 'Making charge cannot be negative';
    }
    if (row.huidTrackingEnabled &&
        row.quantityMode == SilverQuantityMode.packet) {
      return 'Use Pieces, Pair or Set mode for HUID tracked silver items';
    }
    if (row.huidTrackingEnabled && row.pieces > 12) {
      return 'Enter large HUID stock in separate item rows';
    }
    final huids = row.huidTrackingEnabled ? row.huidValues : <String>[];
    if (row.huidTrackingEnabled && huids.isEmpty) {
      return 'Enter HUID number for this silver item';
    }
    final invalidHuid = huids.any((value) => value.length != 6);
    if (invalidHuid) {
      return 'HUID must be exactly 6 characters';
    }
    if (row.huidTrackingEnabled && huids.length != row.pieces) {
      return 'Enter one HUID for each silver piece';
    }
    if (huids.toSet().length != huids.length) {
      return 'Duplicate HUID found in the same silver row';
    }
    return null;
  }

  @override
  Future<String?> validateCustomBatch(List<StockRowEntry> rowsToSave) async {
    if (rowsToSave.isEmpty) {
      return null;
    }
    if (_currentBatchPosted || await _isCurrentBatchAlreadyPosted()) {
      return 'This silver batch has already been saved. Start a new batch before saving again.';
    }
    final supplierValidation = await _supplierInvoicePolicy.validate(
      supplierId: linkedSupplier?.id ?? sessionSupplierId,
      gstEnabled: gstEnabled,
      supplierGstin: supplierGstCtrl.text,
      supplierInvoiceNo: supplierInvoiceNumberCtrl.text,
      hasBillAttachment: hasBillPhoto,
      currentBatchCode: batchCode,
    );
    if (supplierValidation != null) {
      return supplierValidation;
    }
    if (payment.todayRatePerKg <= 0) {
      return 'Enter the silver invoice rate before saving this batch.';
    }
    return null;
  }

  @override
  Future<bool> saveAll() async {
    final saved = await super.saveAll();
    if (saved) {
      _currentBatchPosted = true;
    }
    return saved;
  }

  Future<bool> _isCurrentBatchAlreadyPosted() async {
    return StockBatchPostingGuard.isVoucherPosted(
      db: _rateDb,
      batchCode: batchCode,
    );
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
    await _ensureCurrentBatchCodeIsAvailable();
    final invoiceCategory = _supplierInvoicePolicy.categoryFor(
      gstEnabled: gstEnabled,
    );
    final creditStatus = _supplierInvoicePolicy.creditStatusFor(
      gstEnabled: gstEnabled,
    );
    final supplierName = supplierDisplayName.trim().isNotEmpty
        ? supplierDisplayName.trim()
        : supplierNameCtrl.text.trim();

    return PurchaseVoucherDraft(
      sequenceNo: sequenceNo,
      voucherNo: batchCode,
      supplierInvoiceNo: supplierInvoiceNumberCtrl.text.trim().isEmpty
          ? null
          : supplierInvoiceNumberCtrl.text.trim(),
      source: PurchaseSource.fromSupplier,
      taxType: gstEnabled ? PurchaseTaxType.gst : PurchaseTaxType.normal,
      discountType: PurchaseDiscountType.flatAmount,
      discountValue: snapshot.cashDiscountAmount,
      discountAmount: snapshot.cashDiscountAmount,
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
      ratePerKg: snapshot.ratePerKg,
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
        'purchaseCategory': invoiceCategory.storageValue,
        'purchaseCategoryLabel': invoiceCategory.label,
        'inputCreditStatus': creditStatus.storageValue,
        'inputCreditStatusLabel': creditStatus.label,
        'supplierInvoiceNo': supplierInvoiceNumberCtrl.text.trim(),
        'supplierBillAttachmentPath': _billPhotoPath,
        'supplierBillAttachmentRequired': gstEnabled,
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
              metal: PurchaseMetalType.silver,
              description: row.itemName.trim(),
              companyLabel: row.companyLabel.trim(),
              segmentLabel: row.segmentLabel.trim(),
              quantity: row.quantity,
              grossWeight: row.grossWeight,
              lessWeight: row.lessWeight,
              netWeight: row.netWeight,
              purity: row.resolveTouch(selectedPurityBasePercent),
              fineWeight: row.fineWeight(selectedPurityBasePercent),
              wastageFineWeight: row.wastageFineWeight,
              valuationFineWeight: row.valuationFine(selectedPurityBasePercent),
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
              huids: row.huids
                  .map((value) => value.trim().toUpperCase())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false),
              hsnCode: row.hsnCode.trim().isEmpty
                  ? defaultHsnCode
                  : row.hsnCode.trim(),
              labourCharge: row.makingCharges,
              labourType: row.makingChargesType,
              purityLabel: resolvedPurityStorageLabel(row),
              effectiveRatePerGram: row.purchaseRate,
              gstRate: gstEnabled ? gstRate : 0.0,
              quantityMode: row.quantityMode,
              packetCount: row.packetCount,
              piecesPerPacket: row.piecesPerPacket,
              weightsAreLineTotals: true,
              stockTrackingMode: row.huids.isEmpty
                  ? PurchaseStockTrackingMode.lot
                  : PurchaseStockTrackingMode.unit,
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
    return '${rowsToSave.length} silver row${rowsToSave.length == 1 ? '' : 's'} saved under voucher ${result.voucherNo}. Payment split and supplier settlement have been linked to this batch.';
  }

  @override
  void addRow({bool requestFocus = false}) {
    _addSilverModel(requestFocus: requestFocus);
  }

  void _addSilverModel({bool requestFocus = false}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = SilverItemModel(
      id: id,
      initialWastagePercent: 0.0,
      initialPurchaseRate: silverRatePerGram,
      initialPieces: 1,
    );
    model.setFineRoundOffEnabled(_roundOffInvoiceFine, notify: false);
    model.addListener(notifyListeners);
    _silverRows.add(model);
    if (requestFocus) {
      _pendingSilverFocusId = id;
    }
    notifyListeners();
  }

  @override
  void removeRow(String rowId) {
    final index = _silverRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    final model = _silverRows[index];
    model.removeListener(notifyListeners);
    _silverRows.removeAt(index);

    if (_activeSilverRowId == rowId) {
      _activeSilverRowId = _silverRows.isNotEmpty ? _silverRows.last.id : null;
    }
    if (_pendingSilverFocusId == rowId) {
      _pendingSilverFocusId = null;
    }

    model.disposeAll();
    notifyListeners();
  }

  @override
  void removeActiveRow() {
    if (_silverRows.isEmpty) {
      return;
    }
    final targetId = _activeSilverRowId != null &&
            _silverRows.any((row) => row.id == _activeSilverRowId)
        ? _activeSilverRowId!
        : _silverRows.last.id;
    removeRow(targetId);
  }

  void setSilverActiveRow(String id) => _activeSilverRowId = id;

  bool shouldRequestSilverFocus(String id) => _pendingSilverFocusId == id;

  void clearSilverFocusRequest(String id) {
    if (_pendingSilverFocusId == id) {
      _pendingSilverFocusId = null;
    }
  }

  void completeRowAndAdvanceSilver(String rowId) {
    final index = _silverRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    for (var i = index + 1; i < _silverRows.length; i++) {
      if (!_silverRows[i].hasAnyInput) {
        _pendingSilverFocusId = _silverRows[i].id;
        notifyListeners();
        return;
      }
    }

    _addSilverModel(requestFocus: true);
  }

  void roundOffInvoiceFine() {
    if (!canRoundOffInvoiceFine) {
      return;
    }

    _roundOffInvoiceFine = true;
    for (final row in enteredSilverRows) {
      if (row.hasAnyInput) {
        row.roundFineWeightToNearestGram();
      }
    }
    notifyListeners();
  }

  @override
  void resetAllRows() {
    _roundOffInvoiceFine = false;
    _intakeMode = SilverIntakeMode.singleGrade;
    _clearSilverRows();
    notifyListeners();
  }

  @override
  void resetForNewBatch() {
    _startNewBatchIdentity(notify: false);
    supplierInvoiceNumberCtrl.clear();
    _billPhotoPath = null;
    _supplierLedger = null;
    _isLoadingSupplierLedger = false;
    _roundOffInvoiceFine = false;
    _intakeMode = SilverIntakeMode.singleGrade;
    _currentBatchPosted = false;
    payment.resetSettlement();
    _clearSilverRows();
    super.resetForNewBatch();
    _loadSilverRateSnapshot();
  }

  void _startNewBatchIdentity({bool notify = true}) {
    _silverBatchCreatedAt = DateTime.now();
    _silverBatchCode = SilverBatchCodeGenerator.previewCode(
      _silverBatchCreatedAt,
    );
    _refreshBatchCode();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _refreshBatchCode() async {
    _isLoadingBatchCode = true;
    notifyListeners();
    try {
      final nextCode = await _batchCodeGenerator.nextCodeFor(
        _silverBatchCreatedAt,
      );
      if (nextCode.trim().isNotEmpty) {
        _silverBatchCode = nextCode;
      }
    } finally {
      _isLoadingBatchCode = false;
      notifyListeners();
    }
  }

  Future<void> _ensureCurrentBatchCodeIsAvailable() async {
    final nextCode = await _batchCodeGenerator.nextAvailableCodeFor(
      _silverBatchCreatedAt,
      _silverBatchCode,
    );
    if (_silverBatchCode == nextCode) {
      return;
    }
    _silverBatchCode = nextCode;
    notifyListeners();
  }

  void _clearSilverRows() {
    for (final row in _silverRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _silverRows.clear();
    _pendingSilverFocusId = null;
    _activeSilverRowId = null;
  }

  @override
  void dispose() {
    supplierInvoiceNumberCtrl.dispose();
    payment.removeListener(_syncPurchaseValuationRateToRows);
    payment.dispose();
    for (final row in _silverRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _silverRows.clear();
    super.dispose();
  }

  Future<void> _loadSilverRateSnapshot() async {
    _isLoadingSilverRate = true;
    notifyListeners();

    try {
      final masterProfile =
          await MetalRateRepository().loadProfile(MetalRateMetal.silver);
      final selectedKey = _normaliseSilverRateKey(_defaultSilverPurityLabel());
      var masterRate = 0.0;
      for (final plan in masterProfile.purityPlans) {
        final planKey = _normaliseSilverRateKey(plan.label);
        if (planKey == selectedKey) {
          masterRate = plan.manualDisplayRatePer10g > 0
              ? plan.manualDisplayRatePer10g
              : masterProfile.marketBaseRatePer10g * plan.purityFactor;
          break;
        }
      }
      if (masterRate <= 0 && masterProfile.purityPlans.isNotEmpty) {
        final first = masterProfile.purityPlans.first;
        masterRate = first.manualDisplayRatePer10g > 0
            ? first.manualDisplayRatePer10g
            : masterProfile.marketBaseRatePer10g * first.purityFactor;
      }

      final latestRate = await (_rateDb.select(_rateDb.dailyRates)
            ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
            ..limit(1))
          .getSingleOrNull();

      if (masterRate > 0) {
        _silverRatePer10g = masterRate;
        _silverRateDate = masterProfile.updatedAt;
      } else if (latestRate != null) {
        final jewelleryRate = _parseSilverRate(latestRate.silverJewellery);
        final kgRate = _parseSilverRate(latestRate.silverRateKg);
        _silverRatePer10g = jewelleryRate > 0 ? jewelleryRate : kgRate / 100.0;
        _silverRateDate = latestRate.rateDate;
      } else {
        _silverRatePer10g = 0.0;
        _silverRateDate = null;
      }

      payment.setTodayRate(silverRatePerGram * 1000);

      for (final row in _silverRows) {
        row.applyPurchaseRate(silverRatePerGram, onlyIfEmpty: false);
      }
    } catch (_) {
      _silverRatePer10g = 0.0;
      _silverRateDate = null;
    }

    _isLoadingSilverRate = false;
    notifyListeners();
  }

  String _defaultSilverPurityLabel() {
    final trimmed = purityDisplay.trim().toUpperCase();
    final codeMatch = RegExp(r'\b(999|925|800|700)\b').firstMatch(trimmed);
    if (codeMatch != null) {
      return codeMatch.group(1)!;
    }
    return trimmed;
  }

  String _normaliseSilverRateKey(String value) {
    final normalized = value.trim().toUpperCase();
    final codeMatch = RegExp(r'\b(999|925|800|700)\b').firstMatch(normalized);
    if (codeMatch != null) {
      return codeMatch.group(1)!;
    }
    final percentMatch =
        RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%').firstMatch(normalized);
    if (percentMatch != null) {
      final percent = double.tryParse(percentMatch.group(1) ?? '');
      if (percent != null) {
        if (percent >= 99.5) return '999';
        if ((percent - 92.5).abs() <= 0.2) return '925';
        if ((percent - 80.0).abs() <= 0.2) return '800';
        if ((percent - 70.0).abs() <= 0.2) return '700';
        return percent.toStringAsFixed(2);
      }
    }
    return normalized.replaceAll(' ', '');
  }

  StockSubCategory _mapSilverSubCategory(String categoryLabel) {
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

  double _parseSilverRate(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  void _syncPurchaseValuationRateToRows() {
    final ratePerGram = payment.todayRatePerGram;
    if (ratePerGram <= 0) {
      return;
    }

    var changed = false;
    for (final row in _silverRows) {
      if ((row.purchaseRate - ratePerGram).abs() < 0.0001) {
        continue;
      }
      row.applyPurchaseRate(ratePerGram, onlyIfEmpty: false);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}
