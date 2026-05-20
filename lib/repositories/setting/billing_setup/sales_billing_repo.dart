// =============================================================================
// FILE        : lib/repositories/setting/billing/sales_billing_repo.dart
// MODULE      : Billing Setup → Sales
// DESCRIPTION : DB read/write for sales billing settings.
//               Upsert pattern: one row per metal, insert or update.
// =============================================================================

import '../../../database/db/app_database.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import 'package:drift/drift.dart';

class SalesBillingRepo {
  final AppDatabase _db = AppDatabase();

  // ── Fetch settings for one metal ─────────────────────────────────────────
  Future<SalesBillingModel> fetchForMetal(String metal) async {
    final row = await (_db.select(_db.salesBillingSettings)
          ..where((t) => t.metal.equals(metal)))
        .getSingleOrNull();

    if (row == null) return SalesBillingModel.defaultFor(metal);
    return _rowToModel(row);
  }

  // ── Save settings for one metal (upsert) ─────────────────────────────────
  Future<bool> saveForMetal(SalesBillingModel model) async {
    try {
      await _db.into(_db.salesBillingSettings).insertOnConflictUpdate(
            SalesBillingSettingsCompanion.insert(
              metal: model.metal,
              showPieces: Value(model.showPieces),
              showGrossWeight: Value(model.showGrossWeight),
              showLessWeight: Value(model.showLessWeight),
              showNetWeight: Value(model.showNetWeight),
              showPurity: Value(model.showPurity),
              showRate: Value(model.showRate),
              showMakingCharges: Value(model.showMakingCharges),
              showMakingChargeType: Value(model.showMakingChargeType),
              showStoneDetails: Value(model.showStoneDetails),
              showStoneValue: Value(model.showStoneValue),
              showTotalValue: Value(model.showTotalValue),
              showHuid: Value(model.showHuid),
              showWastage: Value(model.showWastage),
              showOldGoldLine: Value(model.showOldGoldLine),
              showDiamondClarity: Value(model.showDiamondClarity),
              showCertificationNo: Value(model.showCertificationNo),
              showDiamondCarats: Value(model.showDiamondCarats),
              showDiamondPieces: Value(model.showDiamondPieces),
              showMetalWeight: Value(model.showMetalWeight),
              showFineWeight: Value(model.showFineWeight),
              showGstBreakup: Value(model.showGstBreakup),
              showHsnCode: Value(model.showHsnCode),
              returnWindowDays: Value(model.returnWindowDays),
              returnMode: Value(model.returnMode),
              handlingChargePercent: Value(model.handlingChargePercent),
              buybackRatePercent: Value(model.buybackRatePercent),
              buybackPurityDeductPercent:
                  Value(model.buybackPurityDeductPercent),
              termsAndConditions: Value(model.termsAndConditions),
              returnPolicyText: Value(model.returnPolicyText),
              buybackPolicyText: Value(model.buybackPolicyText),
              footerMessage: Value(model.footerMessage),
              selectedTemplate: Value(model.selectedTemplate),
            ),
          );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Seed defaults for all 4 metals (called on first app launch) ───────────
  Future<void> seedDefaults() async {
    for (final metal in BillingMetal.all) {
      final existing = await (_db.select(_db.salesBillingSettings)
            ..where((t) => t.metal.equals(metal)))
          .getSingleOrNull();
      if (existing == null) {
        await saveForMetal(SalesBillingModel.defaultFor(metal));
      }
    }
  }

  // ── Map DB row → model ────────────────────────────────────────────────────
  SalesBillingModel _rowToModel(SalesBillingSetting row) {
    return SalesBillingModel(
      metal: row.metal,
      showPieces: row.showPieces,
      showGrossWeight: row.showGrossWeight,
      showLessWeight: row.showLessWeight,
      showNetWeight: row.showNetWeight,
      showPurity: row.showPurity,
      showRate: row.showRate,
      showMakingCharges: row.showMakingCharges,
      showMakingChargeType: row.showMakingChargeType,
      showStoneDetails: row.showStoneDetails,
      showStoneValue: row.showStoneValue,
      showTotalValue: row.showTotalValue,
      showHuid: row.showHuid,
      showWastage: row.showWastage,
      showOldGoldLine: row.showOldGoldLine,
      showDiamondClarity: row.showDiamondClarity,
      showCertificationNo: row.showCertificationNo,
      showDiamondCarats: row.showDiamondCarats,
      showDiamondPieces: row.showDiamondPieces,
      showMetalWeight: row.showMetalWeight,
      showFineWeight: row.showFineWeight,
      showGstBreakup: row.showGstBreakup,
      showHsnCode: row.showHsnCode,
      returnWindowDays: row.returnWindowDays,
      returnMode: row.returnMode,
      handlingChargePercent: row.handlingChargePercent,
      buybackRatePercent: row.buybackRatePercent,
      buybackPurityDeductPercent: row.buybackPurityDeductPercent,
      termsAndConditions: row.termsAndConditions,
      returnPolicyText: row.returnPolicyText,
      buybackPolicyText: row.buybackPolicyText,
      footerMessage: row.footerMessage,
      selectedTemplate: row.selectedTemplate,
    );
  }
}
