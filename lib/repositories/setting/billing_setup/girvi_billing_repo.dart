// =============================================================================
// FILE        : lib/repositories/setting/billing/girvi_billing_repo.dart
// MODULE      : Billing Setup → Girvi
// DESCRIPTION : Single-row upsert pattern. Always 1 row in table.
// =============================================================================

import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';
import '../../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../../core/logging/app_logger.dart';

class GirviBillingRepo {
  final AppDatabase _db;

  GirviBillingRepo({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<GirviBillingModel> fetch() async {
    try {
      await _db.ensureBillingSetupSchema();
      final row = await (_db.select(_db.girviBillingSettings)..limit(1))
          .getSingleOrNull();
      if (row == null) return GirviBillingModel.defaults;
      return _rowToModel(row);
    } catch (e) {
      AppLogger.debug('❌ [GIRVI BILLING REPO] fetch error: $e');
      return GirviBillingModel.defaults;
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<bool> save(GirviBillingModel model) async {
    try {
      await _db.ensureBillingSetupSchema();
      final existing = await (_db.select(_db.girviBillingSettings)..limit(1))
          .getSingleOrNull();

      final companion = GirviBillingSettingsCompanion(
        girviPrefix: Value(model.girviPrefix),
        startingNumber: Value(model.startingNumber),
        defaultInterestRate: Value(model.defaultInterestRate),
        interestType: Value(model.interestType),
        gracePeriodDays: Value(model.gracePeriodDays),
        defaultDuration: Value(model.defaultDuration),
        reminderDays: Value(model.reminderDays),
        noticeDays: Value(model.noticeDays),
        termsAndConditions: Value(model.termsAndConditions),
        termsAndConditionsHindi: Value(model.termsAndConditionsHindi),
        customerDeclaration: Value(model.customerDeclaration),
        customerDeclarationHindi: Value(model.customerDeclarationHindi),
        footerMessage: Value(model.footerMessage),
        autoPrint: Value(model.autoPrint),
        selectedTemplate: Value(GirviBillingTemplateOptions.encode(model)),
      );

      if (existing != null) {
        await (_db.update(_db.girviBillingSettings)
              ..where((t) => t.id.equals(existing.id)))
            .write(companion);
      } else {
        await _db.into(_db.girviBillingSettings).insert(companion);
      }
      AppLogger.debug('✅ [GIRVI BILLING REPO] Saved.');
      return true;
    } catch (e) {
      AppLogger.debug('❌ [GIRVI BILLING REPO] save error: $e');
      return false;
    }
  }

  // ── Seed default if empty ─────────────────────────────────────────────────
  Future<void> seedDefault() async {
    await _db.ensureBillingSetupSchema();
    final existing = await (_db.select(_db.girviBillingSettings)..limit(1))
        .getSingleOrNull();
    if (existing == null) await save(GirviBillingModel.defaults);
  }

  // ── Row → Model ───────────────────────────────────────────────────────────
  GirviBillingModel _rowToModel(GirviBillingSetting row) {
    final usesLegacyBlankFooter = row.footerMessage.trim().isEmpty;
    final base = GirviBillingModel(
      girviPrefix: row.girviPrefix,
      startingNumber: row.startingNumber,
      defaultInterestRate: row.defaultInterestRate,
      interestType: row.interestType,
      gracePeriodDays: row.gracePeriodDays,
      defaultDuration: row.defaultDuration,
      reminderDays: row.reminderDays,
      noticeDays: row.noticeDays,
      termsAndConditions: row.termsAndConditions,
      termsAndConditionsHindi: row.termsAndConditionsHindi,
      customerDeclaration: row.customerDeclaration,
      customerDeclarationHindi: row.customerDeclarationHindi,
      footerMessage: usesLegacyBlankFooter
          ? GirviBillingModel.defaultFooterMessage
          : row.footerMessage,
      autoPrint: row.autoPrint,
      selectedTemplate: row.selectedTemplate,
    );
    final applied =
        GirviBillingTemplateOptions.apply(base, row.selectedTemplate);
    return usesLegacyBlankFooter
        ? applied.copyWith(printFooterMessage: true)
        : applied;
  }
}