import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_batch_code_generator.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_invoice_summary_logic.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_payment_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_supplier_invoice_policy.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:lotus_erp/features/stock/gold/domain/models/gold_item_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';

class GoldStockController extends AddStockController {
  String _goldBatchCode = '';
  DateTime _goldBatchCreatedAt = DateTime.now();
  final AppDatabase _rateDb = AppDatabase();
  late final GoldBatchCodeGenerator _batchCodeGenerator =
      GoldBatchCodeGenerator(_rateDb);
  late final GoldSupplierInvoicePolicy _supplierInvoicePolicy =
      GoldSupplierInvoicePolicy(_rateDb);

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
  bool _isLoadingBatchCode = false;
  bool _currentBatchPosted = false;

  GoldStockController() : super(initialMetal: StockCategory.gold) {
    _startNewBatchIdentity(notify: false);
    payment.addListener(_handlePaymentChanged);
    _loadGoldRateSnapshot();
  }

  @override
  String get batchCode => _goldBatchCode;

  DateTime get batchCreatedAt => _goldBatchCreatedAt;
  bool get isLoadingBatchCode => _isLoadingBatchCode;

  List<GoldItemModel> get goldRows => List.unmodifiable(_goldRows);
  bool get isCurrentBatchPosted => _currentBatchPosted;

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
  double get totalActualFineWeight => totalFineWeight;
  double get totalWastageFineWeight => _roundGoldWeight(
        enteredGoldRows.fold(0.0, (sum, row) => sum + row.wastageFineWeight),
      );
  double get totalValuationFineWeight => _roundGoldWeight(
        enteredGoldRows.fold(0.0, (sum, row) => sum + row.valuationFineWeight),
      );
  double get totalMakingAmount =>
      enteredGoldRows.fold(0.0, (sum, row) => sum + row.makingAmount);
  GoldPaymentSnapshot get paymentSnapshot {
    payment.updateInvoiceSummary(
      fine: totalValuationFineWeight,
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
      valuationFineWeight: payment.totalFineFromItems,
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
      cashDueAmount: payment.cashDueAmount,
      dueAmount: payment.dueAmount,
      fineDueWeight: payment.fineDueWeight,
      fineDueValue: payment.fineDueValue,
      fineReturnWeight: payment.fineReturnWeight,
      fineReturnValue: payment.fineReturnValue,
      supplierCreditFineWeight: payment.supplierCreditFineWeight,
      supplierCreditValue: payment.supplierCreditValue,
      returnAmount: payment.returnAmount,
      hasDue: payment.hasDue,
      hasFineDue: payment.hasFineDue,
      hasFineReturn: payment.hasFineReturn,
      hasSupplierCredit: payment.hasSupplierCredit,
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
    super.setPurity(option);
    _loadGoldRateSnapshot();
  }

  @override
  void setCustomPurity(String value) {
    super.setCustomPurity(value);
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
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
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
      final huids =
          rowModel.huidTrackingEnabled ? rowModel.huidValues : <String>[];
      final row = StockRowEntry(id: rowModel.id, hsnCode: defaultHsnCode);
      row.itemName = rowModel.itemName;
      row.description = rowModel.categoryLabel;
      row.subCategory = _mapGoldSubCategory(rowModel.categoryLabel);
      row.subCategoryLabel = rowModel.categoryLabel;
      row.segmentLabel = rowModel.segmentLabel;
      row.huids = huids;
      row.huid = huids.isEmpty ? '' : huids.first;
      row.grossWeight = rowModel.grossWeight;
      row.stoneWeight = rowModel.lessWeight;
      row.touchPercent = rowModel.basePurityPercent;
      row.wastageFineWeight = rowModel.wastageFineWeight;
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
    if (row.basePurityPercent <= 0 || row.basePurityPercent > 100) {
      return 'Actual purity must be between 0 and 100';
    }
    if (row.wastagePercent < 0) {
      return 'Wastage cannot be negative';
    }
    if (row.purchaseRate <= 0) {
      return 'Gold daily rate is missing. Update Gold jewellery rate first.';
    }
    if (row.makingValue < 0) {
      return 'Making charge cannot be negative';
    }
    if (row.huidTrackingEnabled && row.pieces > 12) {
      return 'For HUID stock, keep one item row up to 12 pieces. Use separate rows for large HUID lots.';
    }
    final huids = row.huidValues;
    if (row.huidTrackingEnabled && huids.length != row.pieces) {
      return 'Enter one HUID for each piece or switch this row to Bulk stock';
    }
    final invalidHuid = huids.any((value) => value.length != 6);
    if (invalidHuid) {
      return 'HUID must be exactly 6 characters';
    }
    if (huids.length > row.pieces) {
      return 'HUID count cannot exceed pieces';
    }
    if (huids.toSet().length != huids.length) {
      return 'Duplicate HUID found in the same item row';
    }
    return null;
  }

  @override
  Future<String?> validateCustomBatch(List<StockRowEntry> rowsToSave) async {
    if (rowsToSave.isEmpty) {
      return null;
    }
    if (_currentBatchPosted || await _isCurrentBatchAlreadyPosted()) {
      return 'This gold batch has already been saved. Use Add More Items or Start New Batch before saving again.';
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
    if (payment.todayRatePer10g <= 0) {
      return 'Enter the Gold invoice rate before saving this batch.';
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
    final code = batchCode.trim();
    if (code.isEmpty) {
      return false;
    }
    try {
      final rows = await _rateDb.customSelect(
        '''
        SELECT 1
        FROM purchase_vouchers
        WHERE voucher_no = ?
        LIMIT 1
        ''',
        variables: [drift.Variable.withString(code)],
      ).get();
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
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
        'purchaseCategory': invoiceCategory.storageValue,
        'purchaseCategoryLabel': invoiceCategory.label,
        'inputCreditStatus': creditStatus.storageValue,
        'inputCreditStatusLabel': creditStatus.label,
        'supplierInvoiceNo': supplierInvoiceNumberCtrl.text.trim(),
        'supplierBillAttachmentPath': _billPhotoPath,
        'supplierBillAttachmentRequired': gstEnabled,
        'discountMode': payment.discountMode.name,
        'ratePerGram': snapshot.ratePerGram,
        'ratePer10g': snapshot.ratePer10g,
        'fineDiscountWeight': snapshot.fineDiscountWeight,
        'cashDiscountAmount': snapshot.cashDiscountAmount,
        'actualFineWeight': totalActualFineWeight,
        'wastageFineWeight': totalWastageFineWeight,
        'valuationFineWeight': totalValuationFineWeight,
        'gstRatePercent': snapshot.gstPercent,
        'metalGstPercent': payment.metalGstPercent,
        'cashGstPercent': payment.cashGstPercent,
        'metalTaxableAmount': payment.metalTaxableAmount,
        'cashTaxableAmount': payment.cashTaxableAmount,
        'metalGstAmount': payment.metalTaxAmount,
        'cashGstAmount': payment.cashTaxAmount,
        'settlementPreference': snapshot.settlementPreference.name,
        'promiseDate':
            snapshot.hasDue ? payment.promiseDate?.toIso8601String() : null,
        'cashBankPaidTotal': snapshot.cashBankPaidTotal,
        'cashTargetAmount': snapshot.cashTargetAmount,
        'cashDueAmount': snapshot.cashDueAmount,
        'dueAmount': snapshot.dueAmount,
        'fineDueWeight': snapshot.fineDueWeight,
        'fineDueValue': snapshot.fineDueValue,
        'fineReturnWeight': snapshot.fineReturnWeight,
        'fineReturnValue': snapshot.fineReturnValue,
        'supplierCreditFineWeight': snapshot.supplierCreditFineWeight,
        'supplierCreditValue': snapshot.supplierCreditValue,
        'returnAmount': snapshot.returnAmount,
        'isSettled': snapshot.isSettled,
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
              metal: PurchaseMetalType.gold,
              description: row.itemName.trim(),
              segmentLabel: row.segmentLabel.trim(),
              quantity: row.quantity,
              grossWeight: row.grossWeight,
              lessWeight: row.lessWeight,
              netWeight: row.netWeight,
              purity: row.resolveTouch(selectedPurityBasePercent),
              fineWeight: _roundGoldWeight(
                row.fineWeight(selectedPurityBasePercent),
              ),
              wastageFineWeight: _roundGoldWeight(
                row.wastageFineWeight,
              ),
              valuationFineWeight: _roundGoldWeight(
                row.valuationFine(selectedPurityBasePercent),
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
              effectiveRatePerGram: snapshot.ratePerGram > 0
                  ? snapshot.ratePerGram
                  : row.purchaseRate,
              gstRate: gstEnabled ? gstRate : 0.0,
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
      initialPurityLabel: '',
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

  void prepareAdditionalItemsAfterSave() {
    _currentBatchPosted = false;
    _startNewBatchIdentity(notify: false);
    supplierInvoiceNumberCtrl.clear();
    _billPhotoPath = null;
    payment.resetSettlement();
    _clearGoldRows();
    _addGoldModel(requestFocus: true);
    _loadGoldRateSnapshot();
    notifyListeners();
  }

  @override
  void resetForNewBatch() {
    _currentBatchPosted = false;
    _startNewBatchIdentity(notify: false);
    supplierInvoiceNumberCtrl.clear();
    _billPhotoPath = null;
    _supplierLedger = null;
    _isLoadingSupplierLedger = false;
    payment.resetSettlement();
    _clearGoldRows();
    super.resetForNewBatch();
    _loadGoldRateSnapshot();
  }

  void _startNewBatchIdentity({bool notify = true}) {
    _goldBatchCreatedAt = DateTime.now();
    _goldBatchCode = GoldBatchCodeGenerator.previewCode(_goldBatchCreatedAt);
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
        _goldBatchCreatedAt,
      );
      if (nextCode.trim().isNotEmpty) {
        _goldBatchCode = nextCode;
      }
    } finally {
      _isLoadingBatchCode = false;
      notifyListeners();
    }
  }

  Future<void> _ensureCurrentBatchCodeIsAvailable() async {
    final nextCode = await _batchCodeGenerator.nextAvailableCodeFor(
      _goldBatchCreatedAt,
      _goldBatchCode,
    );
    if (_goldBatchCode == nextCode) {
      return;
    }
    _goldBatchCode = nextCode;
    notifyListeners();
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

  String _normaliseGoldRateKey(String value) {
    final normalized = value.trim().toUpperCase().replaceAll('KT', 'K');
    if (normalized.isEmpty) {
      return '22K';
    }
    final karatMatch = RegExp(r'\b(\d{1,2})\s*K\b').firstMatch(normalized);
    if (karatMatch != null) {
      return '${karatMatch.group(1)!}K';
    }
    final hallmarkMatch =
        RegExp(r'\b(999|916|833|750|585|375)\b').firstMatch(normalized);
    if (hallmarkMatch != null) {
      return switch (hallmarkMatch.group(1)!) {
        '999' => '24K',
        '916' => '22K',
        '833' => '20K',
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
        if ((percent - 83.3).abs() <= 0.4) return '20K';
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
}
