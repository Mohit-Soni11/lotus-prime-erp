// =============================================================================
// FILE        : lib/repositories/setting/billing/girvi_billing_repo.dart
// MODULE      : Billing Setup → Girvi
// DESCRIPTION : Single-row upsert pattern. Always 1 row in table.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../database/db/app_database.dart';
import '../../../models/setting/billing_setup/girvi_billing_model.dart';

class GirviBillingRepo {
  final AppDatabase _db = AppDatabase();

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<GirviBillingModel> fetch() async {
    try {
      final row = await (_db.select(_db.girviBillingSettings)..limit(1))
          .getSingleOrNull();
      if (row == null) return GirviBillingModel.defaults;
      return _rowToModel(row);
    } catch (e) {
      debugPrint('❌ [GIRVI BILLING REPO] fetch error: $e');
      return GirviBillingModel.defaults;
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<bool> save(GirviBillingModel model) async {
    try {
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
        footerMessage: Value(model.footerMessage),
        autoPrint: Value(model.autoPrint),
        selectedTemplate: Value(model.selectedTemplate),
      );

      if (existing != null) {
        await (_db.update(_db.girviBillingSettings)
              ..where((t) => t.id.equals(existing.id)))
            .write(companion);
      } else {
        await _db.into(_db.girviBillingSettings).insert(companion);
      }
      debugPrint('✅ [GIRVI BILLING REPO] Saved.');
      return true;
    } catch (e) {
      debugPrint('❌ [GIRVI BILLING REPO] save error: $e');
      return false;
    }
  }

  // ── Seed default if empty ─────────────────────────────────────────────────
  Future<void> seedDefault() async {
    final existing = await (_db.select(_db.girviBillingSettings)..limit(1))
        .getSingleOrNull();
    if (existing == null) await save(GirviBillingModel.defaults);
  }

  // ── Row → Model ───────────────────────────────────────────────────────────
  GirviBillingModel _rowToModel(GirviBillingSetting row) {
    return GirviBillingModel(
      girviPrefix: row.girviPrefix,
      startingNumber: row.startingNumber,
      defaultInterestRate: row.defaultInterestRate,
      interestType: row.interestType,
      gracePeriodDays: row.gracePeriodDays,
      defaultDuration: row.defaultDuration,
      reminderDays: row.reminderDays,
      noticeDays: row.noticeDays,
      termsAndConditions: row.termsAndConditions,
      footerMessage: row.footerMessage,
      autoPrint: row.autoPrint,
      selectedTemplate: row.selectedTemplate,
    );
  }
}
