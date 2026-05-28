// =============================================================================
// FILE        : lib/repositories/setting/billing/purchase_billing_repo.dart
// MODULE      : Billing Setup → Purchase
// =============================================================================

import '../../../database/db/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import 'package:drift/drift.dart';

class PurchaseBillingRepo {
  final AppDatabase _db = AppDatabase();

  Future<PurchaseBillingModel> fetchForMetal(String metal) async {
    await _db.ensureBillingSetupSchema();
    final row = await (_db.select(_db.purchaseBillingSettings)
          ..where((t) => t.metal.equals(metal))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return PurchaseBillingModel.defaultFor(metal);
    return _rowToModel(row);
  }

  Future<bool> saveForMetal(PurchaseBillingModel model) async {
    try {
      await _db.ensureBillingSetupSchema();
      await _db.into(_db.purchaseBillingSettings).insertOnConflictUpdate(
            PurchaseBillingSettingsCompanion.insert(
              metal: model.metal,
              showGrossWeight: Value(model.showGrossWeight),
              showLessWeight: Value(model.showLessWeight),
              showNetWeight: Value(model.showNetWeight),
              showPurity: Value(model.showPurity),
              showRate: Value(model.showRate),
              showFineWeight: Value(model.showFineWeight),
              showTotalValue: Value(model.showTotalValue),
              showStoneDetails: Value(model.showStoneDetails),
              showStoneValue: Value(model.showStoneValue),
              showHuid: Value(model.showHuid),
              showSupplierDetails: Value(model.showSupplierDetails),
              showPanNumber: Value(model.showPanNumber),
              showDiamondCarats: Value(model.showDiamondCarats),
              showDiamondClarity: Value(model.showDiamondClarity),
              showCertificationNo: Value(model.showCertificationNo),
              showGstBreakup: Value(model.showGstBreakup),
              showHsnCode: Value(model.showHsnCode),
              returnWindowDays: Value(model.returnWindowDays),
              returnMode: Value(model.returnMode),
              purityDeductPercent: Value(model.purityDeductPercent),
              termsAndConditions: Value(model.termsAndConditions),
              returnPolicyText: Value(model.returnPolicyText),
              buybackPolicyText: Value(model.buybackPolicyText),
              footerMessage: Value(model.footerMessage),
              selectedTemplate: Value(model.selectedTemplate),
            ),
          );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save purchase billing settings for ${model.metal}.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> seedDefaults() async {
    for (final metal in BillingMetal.all) {
      final existing = await (_db.select(_db.purchaseBillingSettings)
            ..where((t) => t.metal.equals(metal)))
          .getSingleOrNull();
      if (existing == null) {
        await saveForMetal(PurchaseBillingModel.defaultFor(metal));
      }
    }
  }

  PurchaseBillingModel _rowToModel(PurchaseBillingSetting row) {
    return PurchaseBillingModel(
      metal: row.metal,
      showGrossWeight: row.showGrossWeight,
      showLessWeight: row.showLessWeight,
      showNetWeight: row.showNetWeight,
      showPurity: row.showPurity,
      showRate: row.showRate,
      showFineWeight: row.showFineWeight,
      showTotalValue: row.showTotalValue,
      showStoneDetails: row.showStoneDetails,
      showStoneValue: row.showStoneValue,
      showHuid: row.showHuid,
      showSupplierDetails: row.showSupplierDetails,
      showPanNumber: row.showPanNumber,
      showDiamondCarats: row.showDiamondCarats,
      showDiamondClarity: row.showDiamondClarity,
      showCertificationNo: row.showCertificationNo,
      showGstBreakup: row.showGstBreakup,
      showHsnCode: row.showHsnCode,
      returnWindowDays: row.returnWindowDays,
      returnMode: row.returnMode,
      purityDeductPercent: row.purityDeductPercent,
      termsAndConditions: row.termsAndConditions,
      returnPolicyText: row.returnPolicyText,
      buybackPolicyText: row.buybackPolicyText,
      footerMessage: row.footerMessage,
      selectedTemplate: row.selectedTemplate,
    );
  }
}
