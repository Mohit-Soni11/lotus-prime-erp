import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/due_management/domain/services/bill_due_policy.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/models/dashboard/daily_counter_model.dart';

class DailyCounterFinanceRepository {
  final AppDatabase db;

  const DailyCounterFinanceRepository(this.db);

  Future<FinanceDueData> load(DashboardDay day) async {
    final bills = await (db.select(db.bills)
          ..where((t) => t.billDate.isBiggerOrEqualValue(day.start))
          ..where((t) => t.billDate.isSmallerThanValue(day.end))
          ..where((t) => t.status.isIn(const [
                'ACTIVE',
                'PARTIALLY_RETURNED',
                'RETURNED',
              ])))
        .get();
    final dueCustomers = <String>{};
    var dueAmount = 0.0;
    for (final bill in bills) {
      final due = BillDuePolicy.customerDue(bill);
      if (due > 0.005) {
        dueCustomers.add(_customerKey(bill));
        dueAmount += due;
      }
    }

    final loans = await (db.select(db.girviLoans)
          ..where((t) => t.startDate.isBiggerOrEqualValue(day.start))
          ..where((t) => t.startDate.isSmallerThanValue(day.end)))
        .get();
    final girviCustomers = loans.map((loan) => loan.customerId).toSet().length;
    final girviAmount =
        loans.fold<double>(0, (sum, loan) => sum + loan.loanAmount);

    return FinanceDueData(
      dueCount: _count(dueCustomers.length, 'Customer'),
      dueAmount: _currency(dueAmount),
      girviCount: _count(loans.length, 'Ticket'),
      girviAmount: _currency(girviAmount),
      girviCustomerCount: _count(girviCustomers, 'Customer'),
      girviCustomerCountRaw: girviCustomers,
      dueAmountRaw: dueAmount,
      girviAmountRaw: girviAmount,
    );
  }

  String _customerKey(Bill bill) {
    if (bill.customerId != null) return 'ID:${bill.customerId}';
    final mobile = bill.mobile?.trim();
    if (mobile != null && mobile.isNotEmpty) return 'M:$mobile';
    final name = bill.customerName?.trim();
    if (name != null && name.isNotEmpty) return 'N:$name';
    return 'B:${bill.id}';
  }

  String _count(int count, String singular) =>
      '$count $singular${count == 1 ? '' : 's'}';

  String _currency(double amount) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹ ',
        decimalDigits: 2,
      ).format(amount);
}
