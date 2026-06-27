import 'package:drift/drift.dart';

import '../../../core/logging/app_logger.dart';
import '../../../database/db/app_database.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';

class SalesBillingRepo {
  final AppDatabase _db;

  SalesBillingRepo({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<SalesBillingModel> fetchForMetal(String metal) async {
    await _db.ensureBillingSetupSchema();
    final rows = await (_db.select(_db.salesBillingSettings)
          ..where((table) => table.metal.equals(metal))
          ..limit(1))
        .get();

    if (rows.isEmpty) return SalesBillingModel.defaultFor(metal);
    return _rowToModel(rows.first);
  }

  Future<bool> saveForMetal(SalesBillingModel model) async {
    try {
      await _db.ensureBillingSetupSchema();
      final companion = _toCompanion(model);
      final existingRows = await (_db.select(_db.salesBillingSettings)
            ..where((table) => table.metal.equals(model.metal)))
          .get();

      if (existingRows.isEmpty) {
        await _db.into(_db.salesBillingSettings).insert(companion);
      } else {
        await (_db.update(_db.salesBillingSettings)
              ..where((table) => table.metal.equals(model.metal)))
            .write(companion);
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save sales billing settings for ${model.metal}.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> seedDefaults() async {
    await _db.ensureBillingSetupSchema();
    for (final metal in BillingMetal.all) {
      final existing = await (_db.select(_db.salesBillingSettings)
            ..where((table) => table.metal.equals(metal)))
          .getSingleOrNull();
      if (existing == null) {
        await saveForMetal(SalesBillingModel.defaultFor(metal));
      }
    }
  }

  SalesBillingSettingsCompanion _toCompanion(SalesBillingModel model) {
    return SalesBillingSettingsCompanion(
      metal: Value(model.metal),
      updatedAt: Value(DateTime.now()),
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
      buybackPurityDeductPercent: Value(model.buybackPurityDeductPercent),
      termsAndConditions: Value(model.termsAndConditions),
      returnPolicyText: Value(model.returnPolicyText),
      buybackPolicyText: Value(model.buybackPolicyText),
      footerMessage: Value(model.footerMessage),
      selectedTemplate: Value(SalesBillingTemplateOptions.encode(model)),
    );
  }

  SalesBillingModel _rowToModel(SalesBillingSetting row) {
    final storedTemplate = row.selectedTemplate;
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
      selectedTemplate: SalesBillingTemplateOptions.baseTemplate(
        storedTemplate,
      ),
      printTermsAndConditions: SalesBillingTemplateOptions.readFlag(
        storedTemplate,
        'terms',
        defaultValue: false,
      ),
      printReturnPolicy: SalesBillingTemplateOptions.readFlag(
        storedTemplate,
        'return',
        defaultValue: false,
      ),
      printBuybackPolicy: SalesBillingTemplateOptions.readFlag(
        storedTemplate,
        'buyback',
        defaultValue: false,
      ),
      printFooterMessage: SalesBillingTemplateOptions.readFlag(
        storedTemplate,
        'footer',
        defaultValue: true,
      ),
    );
  }
}
