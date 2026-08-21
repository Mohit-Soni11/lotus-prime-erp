import 'package:drift/drift.dart';

import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';

class PurchaseBillingRepo {
  final AppDatabase _db;

  PurchaseBillingRepo({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<PurchaseBillingModel> fetchForMetal(String metal) async {
    await _db.ensureBillingSetupSchema();
    final rows = await (_db.select(_db.purchaseBillingSettings)
          ..where((table) => table.metal.equals(metal))
          ..limit(1))
        .get();

    if (rows.isEmpty) return PurchaseBillingModel.defaultFor(metal);
    return _rowToModel(rows.first);
  }

  Future<bool> saveForMetal(PurchaseBillingModel model) async {
    try {
      await _db.ensureBillingSetupSchema();
      final companion = _toCompanion(model);
      final existingRows = await (_db.select(_db.purchaseBillingSettings)
            ..where((table) => table.metal.equals(model.metal)))
          .get();

      if (existingRows.isEmpty) {
        await _db.into(_db.purchaseBillingSettings).insert(companion);
      } else {
        await (_db.update(_db.purchaseBillingSettings)
              ..where((table) => table.metal.equals(model.metal)))
            .write(companion);
      }
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
    await _db.ensureBillingSetupSchema();
    for (final metal in BillingMetal.all) {
      final existing = await (_db.select(_db.purchaseBillingSettings)
            ..where((table) => table.metal.equals(metal)))
          .getSingleOrNull();
      if (existing == null) {
        await saveForMetal(PurchaseBillingModel.defaultFor(metal));
      }
    }
  }

  PurchaseBillingSettingsCompanion _toCompanion(PurchaseBillingModel model) {
    return PurchaseBillingSettingsCompanion(
      metal: Value(model.metal),
      updatedAt: Value(DateTime.now()),
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
      lateReclaimPenaltyAmount: Value(model.lateReclaimPenaltyAmount),
      highValueReclaimThreshold: Value(model.highValueReclaimThreshold),
      highValueReclaimPenaltyPercent:
          Value(model.highValueReclaimPenaltyPercent),
      termsAndConditions: Value(model.termsAndConditions),
      sellerDeclarationText: Value(model.sellerDeclarationText),
      returnPolicyText: Value(model.returnPolicyText),
      buybackPolicyText: Value(model.buybackPolicyText),
      footerMessage: Value(model.footerMessage),
      selectedTemplate: Value(model.selectedTemplate),
    );
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
      lateReclaimPenaltyAmount: row.lateReclaimPenaltyAmount,
      highValueReclaimThreshold: row.highValueReclaimThreshold,
      highValueReclaimPenaltyPercent: row.highValueReclaimPenaltyPercent,
      termsAndConditions: row.termsAndConditions,
      sellerDeclarationText: row.sellerDeclarationText,
      returnPolicyText: row.returnPolicyText,
      buybackPolicyText: row.buybackPolicyText,
      footerMessage: row.footerMessage,
      selectedTemplate: row.selectedTemplate,
    );
  }
}
