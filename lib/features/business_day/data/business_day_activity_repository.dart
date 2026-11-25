import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_repository.dart';

/// Distinguishes a shop day with recorded activity from a date on which the
/// application was merely opened. A failed projection must block exit rather
/// than silently classify business records as an empty day.
class BusinessDayActivityRepository {
  const BusinessDayActivityRepository(this.db);

  final AppDatabase db;

  Future<bool> hasActivity(DateTime day) async {
    if (await DayBookBalanceVerificationRepository(db).fetch(day) != null) {
      return true;
    }

    final summary = await DayBookRepository(db: db).fetchDayBook(day);
    final flow = summary.moneyFlow;
    final custody = summary.custodyPosition;
    final metalSales = summary.customerMetalSales;

    return summary.documents.isNotEmpty ||
        summary.activityEvents.isNotEmpty ||
        summary.expenseRecords.isNotEmpty ||
        summary.stockMovements.isNotEmpty ||
        summary.stockAddedBatches.isNotEmpty ||
        (flow != null &&
            (flow.entries.isNotEmpty ||
                flow.bankOpeningAdditionsByDay.isNotEmpty)) ||
        (custody != null &&
            (custody.received.isNotEmpty || custody.released.isNotEmpty)) ||
        (metalSales != null &&
            (metalSales.goldInvoices > 0 || metalSales.silverInvoices > 0));
  }
}
