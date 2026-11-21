import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';

class CashRegisterTotals {
  final double opening;
  final double moneyIn;
  final double moneyOut;
  final double closing;

  const CashRegisterTotals({
    required this.opening,
    required this.moneyIn,
    required this.moneyOut,
    required this.closing,
  });
}

class CashRegisterRepository {
  final AppDatabase db;

  const CashRegisterRepository(this.db);

  Stream<CashRegisterTotals> watchDay(DashboardDay day) => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cashTransactions,
          db.bankTransactions,
          db.bankAccounts,
          db.shopProfiles,
        },
      )
      .watchSingle()
      .asyncMap((_) => loadDay(day));

  Future<CashRegisterTotals> loadDay(DashboardDay day) async {
    final money = DayBookMoneyRepository(db);
    final openingCash = await money.fetchOpeningCash(day.start);
    final flow = await money.fetch(day.start, openingCash);
    return CashRegisterTotals(
      opening: flow.openingTotal,
      moneyIn: flow.moneyIn,
      moneyOut: flow.moneyOut,
      closing: flow.closingTotal,
    );
  }
}
