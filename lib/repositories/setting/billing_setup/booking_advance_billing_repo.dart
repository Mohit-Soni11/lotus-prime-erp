import 'package:drift/drift.dart';

import '../../../core/logging/app_logger.dart';
import '../../../database/db/app_database.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/setting/billing_setup/booking_advance_billing_model.dart';

class BookingAdvanceBillingRepo {
  final AppDatabase _db;

  BookingAdvanceBillingRepo({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<BookingAdvanceBillingModel> fetch() async {
    await _db.ensureBillingSetupSchema();
    final row = await (_db.select(_db.bookingAdvanceBillingSettings)..limit(1))
        .getSingleOrNull();
    if (row == null) return BookingAdvanceBillingModel.defaults();
    return _rowToModel(row);
  }

  Future<bool> save(BookingAdvanceBillingModel model) async {
    try {
      await _db.ensureBillingSetupSchema();
      final existing = await (_db.select(_db.bookingAdvanceBillingSettings)
            ..limit(1))
          .getSingleOrNull();
      final companion = _toCompanion(model);

      if (existing == null) {
        await _db.into(_db.bookingAdvanceBillingSettings).insert(companion);
      } else {
        await (_db.update(_db.bookingAdvanceBillingSettings)
              ..where((table) => table.id.equals(existing.id)))
            .write(companion);
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save booking advance billing settings.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  BookingAdvanceBillingSettingsCompanion _toCompanion(
    BookingAdvanceBillingModel model,
  ) {
    return BookingAdvanceBillingSettingsCompanion(
      documentPrefix: Value(_resolveDocumentPrefix(model.documentPrefix)),
      defaultBookingType: Value(_resolveBookingType(model.defaultBookingType)),
      defaultDeliveryDays: Value(model.defaultDeliveryDays),
      minimumAdvancePercent: Value(model.minimumAdvancePercent),
      minimumAdvanceAmount: Value(model.minimumAdvanceAmount),
      allowZeroAdvance: Value(model.allowZeroAdvance),
      defaultPrintFormat: Value(_resolvePrintFormat(model.defaultPrintFormat)),
      printCopies: Value(model.printCopies.clamp(1, 5).toInt()),
      includeCustomerAddress: Value(model.includeCustomerAddress),
      includeRateColumn: Value(model.includeRateColumn),
      printTermsAndConditions: Value(model.printTermsAndConditions),
      printFooterMessage: Value(model.printFooterMessage),
      termsAndConditions: Value(model.termsAndConditions),
      footerMessage: Value(model.footerMessage),
      updatedAt: Value(DateTime.now()),
    );
  }

  BookingAdvanceBillingModel _rowToModel(BookingAdvanceBillingSetting row) {
    return BookingAdvanceBillingModel(
      documentPrefix: _resolveDocumentPrefix(row.documentPrefix),
      defaultBookingType: _resolveBookingType(row.defaultBookingType),
      defaultDeliveryDays: row.defaultDeliveryDays,
      minimumAdvancePercent: row.minimumAdvancePercent,
      minimumAdvanceAmount: row.minimumAdvanceAmount,
      allowZeroAdvance: row.allowZeroAdvance,
      defaultPrintFormat: _resolvePrintFormat(row.defaultPrintFormat),
      printCopies: row.printCopies.clamp(1, 5).toInt(),
      includeCustomerAddress: row.includeCustomerAddress,
      includeRateColumn: row.includeRateColumn,
      printTermsAndConditions: row.printTermsAndConditions,
      printFooterMessage: row.printFooterMessage,
      termsAndConditions: row.termsAndConditions.trim().isEmpty
          ? BookingAdvanceBillingModel.defaults().termsAndConditions
          : row.termsAndConditions,
      footerMessage: row.footerMessage.trim().isEmpty
          ? BookingAdvanceBillingModel.defaults().footerMessage
          : row.footerMessage,
    );
  }

  String _resolveDocumentPrefix(String value) {
    final normalized =
        value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.isEmpty
        ? BookingAdvanceBillingModel.defaultDocumentPrefix
        : normalized;
  }

  String _resolveBookingType(String value) {
    final normalized = value.trim().toUpperCase();
    return BookingAdvanceBillingModel.bookingTypes.contains(normalized)
        ? normalized
        : BookingAdvanceBillingModel.bookingTypeOpen;
  }

  String _resolvePrintFormat(String value) {
    final normalized = value.trim();
    for (final format in PrintFormat.values) {
      if (format.name == normalized) return normalized;
    }
    return PrintFormat.a4.name;
  }
}
