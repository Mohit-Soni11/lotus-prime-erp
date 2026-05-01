// =============================================================================
// FILE        : lib/logic/setting/billing_setup/billing_setup_logic.dart
// MODULE      : Billing Setup
// LAYER       : Business Logic / ViewModel
// DESCRIPTION : Granular ValueNotifiers — Zero-Lag 60-FPS rebuilds.
//               Pattern: Identical to BasicInfoLogic.
//               4 logic classes, one per billing module card.
//               lockedNotifier() is PUBLIC — UI can call it.
// =============================================================================

import 'package:flutter/foundation.dart';
import '../../../models/setting/billing_setup/billing_setup_model.dart';
import '../../../repositories/setting/billing_setup/billing_setup_repository.dart';
import '../../../theme/settings/billing_setup/billing_setup_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS — Section identifiers for each billing card
// ═══════════════════════════════════════════════════════════════════════════════
enum BillingSection { invoiceNo, estimate, payment, discount, display, terms }

enum PurchaseSection { invoiceNo, paymentTerms, itemRules, termsAndPrint }

enum GirviSection { voucher, interest, notice, termsAndPrint }

enum ReturnSection { returnPolicy, buyback, terms }

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SALES BILLING LOGIC
// ═══════════════════════════════════════════════════════════════════════════════
class SalesBillingLogic {
  final BillingSetupRepository _repo = BillingSetupRepository();

  // ── Section lock notifiers ───────────────────────────────────────────────
  final ValueNotifier<bool> invoiceNoLocked = ValueNotifier(true);
  final ValueNotifier<bool> estimateLocked = ValueNotifier(true);
  final ValueNotifier<bool> paymentLocked = ValueNotifier(true);
  final ValueNotifier<bool> discountLocked = ValueNotifier(true);
  final ValueNotifier<bool> displayLocked = ValueNotifier(true);
  final ValueNotifier<bool> termsLocked = ValueNotifier(true);

  final ValueNotifier<BillingSection?> loadingSection = ValueNotifier(null);

  // ── Dropdowns & toggles ──────────────────────────────────────────────────
  final ValueNotifier<String> selectedPayMode =
      ValueNotifier(BillingSetupStrings.paymentModes.first);
  final ValueNotifier<String> selectedRounding =
      ValueNotifier(BillingSetupStrings.roundingRules[1]);
  final ValueNotifier<bool> yearlyReset = ValueNotifier(true);
  final ValueNotifier<bool> allowDiscount = ValueNotifier(true);
  final ValueNotifier<bool> showMaking = ValueNotifier(true);
  final ValueNotifier<bool> showHuid = ValueNotifier(true);
  final ValueNotifier<bool> showOldGold = ValueNotifier(true);

  SalesBillingModel? _initial;

  void init(SalesBillingModel? data) {
    if (_initial != null) return;
    _initial = data;
    if (data == null) return;
    selectedPayMode.value = data.defaultPaymentMode;
    selectedRounding.value = data.roundingRule;
    yearlyReset.value = data.yearlyReset;
    allowDiscount.value = data.allowDiscount;
    showMaking.value = data.showMakingCharges;
    showHuid.value = data.showHuid;
    showOldGold.value = data.showOldGoldLine;
  }

  // ── PUBLIC: lock/unlock ───────────────────────────────────────────────────
  ValueNotifier<bool> lockedNotifier(BillingSection s) {
    switch (s) {
      case BillingSection.invoiceNo:
        return invoiceNoLocked;
      case BillingSection.estimate:
        return estimateLocked;
      case BillingSection.payment:
        return paymentLocked;
      case BillingSection.discount:
        return discountLocked;
      case BillingSection.display:
        return displayLocked;
      case BillingSection.terms:
        return termsLocked;
    }
  }

  void unlockSection(BillingSection s) => lockedNotifier(s).value = false;
  void lockSection(BillingSection s) => lockedNotifier(s).value = true;

  // ── Save to DB ────────────────────────────────────────────────────────────
  Future<bool> saveSection({
    required BillingSection section,
    required SalesBillingModel model,
  }) async {
    loadingSection.value = section;
    final ok = await _repo.saveSalesSettings(model);
    loadingSection.value = null;
    if (ok) lockSection(section);
    return ok;
  }

  // ── Build model from controller values ────────────────────────────────────
  SalesBillingModel buildModel({
    required String prefix,
    required String startNo,
    required String estPrefix,
    required String estDays,
    required String upiId,
    required String creditDays,
    required String minAdvance,
    required String maxDiscount,
    required String terms,
    required String footerMsg,
  }) =>
      SalesBillingModel(
        invoicePrefix: prefix,
        startingNumber: int.tryParse(startNo) ?? 1,
        yearlyReset: yearlyReset.value,
        estimatePrefix: estPrefix,
        estimateValidityDays: int.tryParse(estDays) ?? 7,
        defaultPaymentMode: selectedPayMode.value,
        upiId: upiId,
        defaultCreditDays: int.tryParse(creditDays) ?? 30,
        minAdvancePercent: int.tryParse(minAdvance) ?? 30,
        allowDiscount: allowDiscount.value,
        maxDiscountPercent: double.tryParse(maxDiscount) ?? 5.0,
        roundingRule: selectedRounding.value,
        showMakingCharges: showMaking.value,
        showHuid: showHuid.value,
        showOldGoldLine: showOldGold.value,
        terms: terms,
        footerMsg: footerMsg,
      );

  SalesBillingModel get defaults => _initial ?? const SalesBillingModel();

  void dispose() {
    invoiceNoLocked.dispose();
    estimateLocked.dispose();
    paymentLocked.dispose();
    discountLocked.dispose();
    displayLocked.dispose();
    termsLocked.dispose();
    loadingSection.dispose();
    selectedPayMode.dispose();
    selectedRounding.dispose();
    yearlyReset.dispose();
    allowDiscount.dispose();
    showMaking.dispose();
    showHuid.dispose();
    showOldGold.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. PURCHASE BILLING LOGIC
// ═══════════════════════════════════════════════════════════════════════════════
class PurchaseBillingLogic {
  final BillingSetupRepository _repo = BillingSetupRepository();

  final ValueNotifier<bool> invoiceNoLocked = ValueNotifier(true);
  final ValueNotifier<bool> paymentTermsLocked = ValueNotifier(true);
  final ValueNotifier<bool> itemRulesLocked = ValueNotifier(true);
  final ValueNotifier<bool> termsLocked = ValueNotifier(true);

  final ValueNotifier<PurchaseSection?> loadingSection = ValueNotifier(null);

  final ValueNotifier<String> selectedPayMode =
      ValueNotifier(BillingSetupStrings.purchasePayModes[1]);
  final ValueNotifier<String> selectedKarat =
      ValueNotifier(BillingSetupStrings.karatOptions[1]);
  final ValueNotifier<bool> yearlyReset = ValueNotifier(true);
  final ValueNotifier<bool> autoPrint = ValueNotifier(false);

  PurchaseBillingModel? _initial;

  void init(PurchaseBillingModel? data) {
    if (_initial != null) return;
    _initial = data;
    if (data == null) return;
    selectedPayMode.value = data.defaultPaymentMode;
    selectedKarat.value = data.defaultKarat;
    yearlyReset.value = data.yearlyReset;
    autoPrint.value = data.autoPrint;
  }

  ValueNotifier<bool> lockedNotifier(PurchaseSection s) {
    switch (s) {
      case PurchaseSection.invoiceNo:
        return invoiceNoLocked;
      case PurchaseSection.paymentTerms:
        return paymentTermsLocked;
      case PurchaseSection.itemRules:
        return itemRulesLocked;
      case PurchaseSection.termsAndPrint:
        return termsLocked;
    }
  }

  void unlockSection(PurchaseSection s) => lockedNotifier(s).value = false;
  void lockSection(PurchaseSection s) => lockedNotifier(s).value = true;

  Future<bool> saveSection({
    required PurchaseSection section,
    required PurchaseBillingModel model,
  }) async {
    loadingSection.value = section;
    final ok = await _repo.savePurchaseSettings(model);
    loadingSection.value = null;
    if (ok) lockSection(section);
    return ok;
  }

  PurchaseBillingModel buildModel({
    required String prefix,
    required String startNo,
    required String payDays,
    required String advance,
    required String weightTol,
    required String terms,
  }) =>
      PurchaseBillingModel(
        invoicePrefix: prefix,
        startingNumber: int.tryParse(startNo) ?? 1,
        yearlyReset: yearlyReset.value,
        defaultPaymentDays: int.tryParse(payDays) ?? 30,
        advancePercent: int.tryParse(advance) ?? 20,
        defaultPaymentMode: selectedPayMode.value,
        weightTolerancePercent: double.tryParse(weightTol) ?? 0.5,
        defaultKarat: selectedKarat.value,
        terms: terms,
        autoPrint: autoPrint.value,
      );

  PurchaseBillingModel get defaults => _initial ?? const PurchaseBillingModel();

  void dispose() {
    invoiceNoLocked.dispose();
    paymentTermsLocked.dispose();
    itemRulesLocked.dispose();
    termsLocked.dispose();
    loadingSection.dispose();
    selectedPayMode.dispose();
    selectedKarat.dispose();
    yearlyReset.dispose();
    autoPrint.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. GIRVI BILLING LOGIC
// ═══════════════════════════════════════════════════════════════════════════════
class GirviBillingLogic {
  final BillingSetupRepository _repo = BillingSetupRepository();

  final ValueNotifier<bool> voucherLocked = ValueNotifier(true);
  final ValueNotifier<bool> interestLocked = ValueNotifier(true);
  final ValueNotifier<bool> noticeLocked = ValueNotifier(true);
  final ValueNotifier<bool> termsLocked = ValueNotifier(true);

  final ValueNotifier<GirviSection?> loadingSection = ValueNotifier(null);

  final ValueNotifier<String> selectedInterestType =
      ValueNotifier(BillingSetupStrings.interestTypes.first);
  final ValueNotifier<String> selectedDuration =
      ValueNotifier(BillingSetupStrings.girviDurations[2]);
  final ValueNotifier<bool> autoPrint = ValueNotifier(true);

  GirviBillingModel? _initial;

  void init(GirviBillingModel? data) {
    if (_initial != null) return;
    _initial = data;
    if (data == null) return;
    selectedInterestType.value = data.interestType;
    selectedDuration.value = data.defaultDuration;
    autoPrint.value = data.autoPrint;
  }

  ValueNotifier<bool> lockedNotifier(GirviSection s) {
    switch (s) {
      case GirviSection.voucher:
        return voucherLocked;
      case GirviSection.interest:
        return interestLocked;
      case GirviSection.notice:
        return noticeLocked;
      case GirviSection.termsAndPrint:
        return termsLocked;
    }
  }

  void unlockSection(GirviSection s) => lockedNotifier(s).value = false;
  void lockSection(GirviSection s) => lockedNotifier(s).value = true;

  Future<bool> saveSection({
    required GirviSection section,
    required GirviBillingModel model,
  }) async {
    loadingSection.value = section;
    final ok = await _repo.saveGirviSettings(model);
    loadingSection.value = null;
    if (ok) lockSection(section);
    return ok;
  }

  GirviBillingModel buildModel({
    required String prefix,
    required String startNo,
    required String interestRate,
    required String grace,
    required String reminder,
    required String notice,
    required String terms,
  }) =>
      GirviBillingModel(
        girviPrefix: prefix,
        startingNumber: int.tryParse(startNo) ?? 1,
        defaultInterestRate: double.tryParse(interestRate) ?? 1.5,
        interestType: selectedInterestType.value,
        gracePeriodDays: int.tryParse(grace) ?? 3,
        defaultDuration: selectedDuration.value,
        reminderDays: int.tryParse(reminder) ?? 15,
        noticeDays: int.tryParse(notice) ?? 30,
        terms: terms,
        autoPrint: autoPrint.value,
      );

  GirviBillingModel get defaults => _initial ?? const GirviBillingModel();

  void dispose() {
    voucherLocked.dispose();
    interestLocked.dispose();
    noticeLocked.dispose();
    termsLocked.dispose();
    loadingSection.dispose();
    selectedInterestType.dispose();
    selectedDuration.dispose();
    autoPrint.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. RETURN & BUYBACK LOGIC
// ═══════════════════════════════════════════════════════════════════════════════
class ReturnBillingLogic {
  final BillingSetupRepository _repo = BillingSetupRepository();

  final ValueNotifier<bool> policyLocked = ValueNotifier(true);
  final ValueNotifier<bool> buybackLocked = ValueNotifier(true);
  final ValueNotifier<bool> termsLocked = ValueNotifier(true);

  final ValueNotifier<ReturnSection?> loadingSection = ValueNotifier(null);

  final ValueNotifier<String> selectedReturnMode =
      ValueNotifier(BillingSetupStrings.returnModes.first);
  final ValueNotifier<String> selectedKarat =
      ValueNotifier(BillingSetupStrings.karatOptions[1]);

  ReturnBillingModel? _initial;

  void init(ReturnBillingModel? data) {
    if (_initial != null) return;
    _initial = data;
    if (data == null) return;
    selectedReturnMode.value = data.returnMode;
    selectedKarat.value = data.buybackDefaultKarat;
  }

  ValueNotifier<bool> lockedNotifier(ReturnSection s) {
    switch (s) {
      case ReturnSection.returnPolicy:
        return policyLocked;
      case ReturnSection.buyback:
        return buybackLocked;
      case ReturnSection.terms:
        return termsLocked;
    }
  }

  void unlockSection(ReturnSection s) => lockedNotifier(s).value = false;
  void lockSection(ReturnSection s) => lockedNotifier(s).value = true;

  Future<bool> saveSection({
    required ReturnSection section,
    required ReturnBillingModel model,
  }) async {
    loadingSection.value = section;
    final ok = await _repo.saveReturnSettings(model);
    loadingSection.value = null;
    if (ok) lockSection(section);
    return ok;
  }

  ReturnBillingModel buildModel({
    required String window,
    required String handling,
    required String voucher,
    required String rate,
    required String purity,
    required String terms,
  }) =>
      ReturnBillingModel(
        returnWindowDays: int.tryParse(window) ?? 7,
        handlingChargePercent: double.tryParse(handling) ?? 0.0,
        returnMode: selectedReturnMode.value,
        returnVoucherPrefix: voucher,
        buybackRatePercent: double.tryParse(rate) ?? 90.0,
        buybackPurityDeductPercent: double.tryParse(purity) ?? 2.0,
        buybackDefaultKarat: selectedKarat.value,
        terms: terms,
      );

  ReturnBillingModel get defaults => _initial ?? const ReturnBillingModel();

  void dispose() {
    policyLocked.dispose();
    buybackLocked.dispose();
    termsLocked.dispose();
    loadingSection.dispose();
    selectedReturnMode.dispose();
    selectedKarat.dispose();
  }
}
