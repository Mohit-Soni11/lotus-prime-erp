// =============================================================================
// FILE        : lib/repositories/setting/billing_setup/billing_setup_repository.dart
// MODULE      : Billing Setup
// LAYER       : Repository / Data Access Layer
// DESCRIPTION : Reads and writes all 4 billing config groups to Drift DB.
//               Upsert pattern — same as ShopSetupRepository.
//               Singleton table: always update row id=1.
// NOTE        : BillingSetting & BillingSettingsCompanion are Drift-generated
//               classes. Run build_runner after adding BillingSettings to
//               AppDatabase tables list to generate app_database.g.dart.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../database/db/app_database.dart';
import '../../../models/setting/billing_setup/billing_setup_model.dart';

class BillingSetupRepository {
  final AppDatabase _db = AppDatabase();

  // ── FETCH ─────────────────────────────────────────────────────────────────
  Future<BillingSetting?> fetchSettings() async {
    try {
      final result =
          await (_db.select(_db.billingSettings)..limit(1)).getSingleOrNull();
      debugPrint('✅ [BILLING REPO] Settings loaded: ${result?.id}');
      return result;
    } catch (e) {
      debugPrint('❌ [BILLING REPO] fetchSettings error: $e');
      return null;
    }
  }

  // ── SAVE SALES ─────────────────────────────────────────────────────────────
  Future<bool> saveSalesSettings(SalesBillingModel m) async {
    try {
      return await _upsert(BillingSettingsCompanion(
        salesInvoicePrefix: Value(m.invoicePrefix),
        salesStartingNumber: Value(m.startingNumber),
        salesYearlyReset: Value(m.yearlyReset),
        estimatePrefix: Value(m.estimatePrefix),
        estimateValidityDays: Value(m.estimateValidityDays),
        salesDefaultPaymentMode: Value(m.defaultPaymentMode),
        salesUpiId: Value(m.upiId),
        salesDefaultCreditDays: Value(m.defaultCreditDays),
        salesMinAdvancePercent: Value(m.minAdvancePercent),
        salesAllowDiscount: Value(m.allowDiscount),
        salesMaxDiscountPercent: Value(m.maxDiscountPercent),
        salesRoundingRule: Value(m.roundingRule),
        salesShowMakingCharges: Value(m.showMakingCharges),
        salesShowHuid: Value(m.showHuid),
        salesShowOldGoldLine: Value(m.showOldGoldLine),
        salesTerms: Value(m.terms),
        salesFooterMsg: Value(m.footerMsg),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('❌ [BILLING REPO] saveSalesSettings: $e');
      return false;
    }
  }

  // ── SAVE PURCHASE ──────────────────────────────────────────────────────────
  Future<bool> savePurchaseSettings(PurchaseBillingModel m) async {
    try {
      return await _upsert(BillingSettingsCompanion(
        purchaseInvoicePrefix: Value(m.invoicePrefix),
        purchaseStartingNumber: Value(m.startingNumber),
        purchaseYearlyReset: Value(m.yearlyReset),
        purchaseDefaultPaymentDays: Value(m.defaultPaymentDays),
        purchaseAdvancePercent: Value(m.advancePercent),
        purchaseDefaultPaymentMode: Value(m.defaultPaymentMode),
        purchaseWeightTolerancePercent: Value(m.weightTolerancePercent),
        purchaseDefaultKarat: Value(m.defaultKarat),
        purchaseTerms: Value(m.terms),
        purchaseAutoPrint: Value(m.autoPrint),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('❌ [BILLING REPO] savePurchaseSettings: $e');
      return false;
    }
  }

  // ── SAVE GIRVI ─────────────────────────────────────────────────────────────
  Future<bool> saveGirviSettings(GirviBillingModel m) async {
    try {
      return await _upsert(BillingSettingsCompanion(
        girviPrefix: Value(m.girviPrefix),
        girviStartingNumber: Value(m.startingNumber),
        girviDefaultInterestRate: Value(m.defaultInterestRate),
        girviInterestType: Value(m.interestType),
        girviGracePeriodDays: Value(m.gracePeriodDays),
        girviDefaultDuration: Value(m.defaultDuration),
        girviReminderDays: Value(m.reminderDays),
        girviNoticeDays: Value(m.noticeDays),
        girviTerms: Value(m.terms),
        girviAutoPrint: Value(m.autoPrint),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('❌ [BILLING REPO] saveGirviSettings: $e');
      return false;
    }
  }

  // ── SAVE RETURN ────────────────────────────────────────────────────────────
  Future<bool> saveReturnSettings(ReturnBillingModel m) async {
    try {
      return await _upsert(BillingSettingsCompanion(
        returnWindowDays: Value(m.returnWindowDays),
        returnHandlingChargePercent: Value(m.handlingChargePercent),
        returnMode: Value(m.returnMode),
        returnVoucherPrefix: Value(m.returnVoucherPrefix),
        buybackRatePercent: Value(m.buybackRatePercent),
        buybackPurityDeductPercent: Value(m.buybackPurityDeductPercent),
        buybackDefaultKarat: Value(m.buybackDefaultKarat),
        returnTerms: Value(m.terms),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('❌ [BILLING REPO] saveReturnSettings: $e');
      return false;
    }
  }

  // ── UPSERT HELPER ──────────────────────────────────────────────────────────
  Future<bool> _upsert(BillingSettingsCompanion companion) async {
    final existing =
        await (_db.select(_db.billingSettings)..limit(1)).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.billingSettings)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
      debugPrint('✅ [BILLING REPO] Updated row id: ${existing.id}');
    } else {
      await _db.into(_db.billingSettings).insert(companion);
      debugPrint('✅ [BILLING REPO] New row inserted.');
    }
    return true;
  }

  // ── ROW → MODEL CONVERTERS ─────────────────────────────────────────────────
  SalesBillingModel rowToSalesModel(BillingSetting r) => SalesBillingModel(
        invoicePrefix: r.salesInvoicePrefix,
        startingNumber: r.salesStartingNumber,
        yearlyReset: r.salesYearlyReset,
        estimatePrefix: r.estimatePrefix,
        estimateValidityDays: r.estimateValidityDays,
        defaultPaymentMode: r.salesDefaultPaymentMode,
        upiId: r.salesUpiId,
        defaultCreditDays: r.salesDefaultCreditDays,
        minAdvancePercent: r.salesMinAdvancePercent,
        allowDiscount: r.salesAllowDiscount,
        maxDiscountPercent: r.salesMaxDiscountPercent,
        roundingRule: r.salesRoundingRule,
        showMakingCharges: r.salesShowMakingCharges,
        showHuid: r.salesShowHuid,
        showOldGoldLine: r.salesShowOldGoldLine,
        terms: r.salesTerms,
        footerMsg: r.salesFooterMsg,
      );

  PurchaseBillingModel rowToPurchaseModel(BillingSetting r) =>
      PurchaseBillingModel(
        invoicePrefix: r.purchaseInvoicePrefix,
        startingNumber: r.purchaseStartingNumber,
        yearlyReset: r.purchaseYearlyReset,
        defaultPaymentDays: r.purchaseDefaultPaymentDays,
        advancePercent: r.purchaseAdvancePercent,
        defaultPaymentMode: r.purchaseDefaultPaymentMode,
        weightTolerancePercent: r.purchaseWeightTolerancePercent,
        defaultKarat: r.purchaseDefaultKarat,
        terms: r.purchaseTerms,
        autoPrint: r.purchaseAutoPrint,
      );

  GirviBillingModel rowToGirviModel(BillingSetting r) => GirviBillingModel(
        girviPrefix: r.girviPrefix,
        startingNumber: r.girviStartingNumber,
        defaultInterestRate: r.girviDefaultInterestRate,
        interestType: r.girviInterestType,
        gracePeriodDays: r.girviGracePeriodDays,
        defaultDuration: r.girviDefaultDuration,
        reminderDays: r.girviReminderDays,
        noticeDays: r.girviNoticeDays,
        terms: r.girviTerms,
        autoPrint: r.girviAutoPrint,
      );

  ReturnBillingModel rowToReturnModel(BillingSetting r) => ReturnBillingModel(
        returnWindowDays: r.returnWindowDays,
        handlingChargePercent: r.returnHandlingChargePercent,
        returnMode: r.returnMode,
        returnVoucherPrefix: r.returnVoucherPrefix,
        buybackRatePercent: r.buybackRatePercent,
        buybackPurityDeductPercent: r.buybackPurityDeductPercent,
        buybackDefaultKarat: r.buybackDefaultKarat,
        terms: r.returnTerms,
      );
}
