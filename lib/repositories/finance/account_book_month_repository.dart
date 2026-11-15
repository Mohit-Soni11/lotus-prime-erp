import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/account_book/account_book_month.dart';
import '../../models/reports/day_book/day_book_money_flow.dart';
import '../reports/day_book_activity_repository.dart';
import '../reports/day_book_document_repository.dart';
import '../reports/day_book_expense_repository.dart';
import '../reports/day_book_money_repository.dart';
import '../reports/day_book_stock_movement_repository.dart';

/// A read-only monthly projection over the same posted sources as Day Book.
/// Document values are informational; only ledger entries move cash or bank.
class AccountBookMonthRepository {
  AccountBookMonthRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  Future<AccountBookMonth> fetch(DateTime selectedMonth) async {
    final start = DateTime(selectedMonth.year, selectedMonth.month);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1);
    return _db.transaction(() async {
      final moneyRepository = DayBookMoneyRepository(_db);
      final openingCash = await moneyRepository.fetchOpeningCash(start);
      final money = await moneyRepository.fetchRange(start, end, openingCash);
      final documents =
          await DayBookDocumentRepository(_db).fetchRange(start, end);
      final movements =
          await DayBookStockMovementRepository(_db).fetchRange(start, end);
      final expenses =
          await DayBookExpenseRepository(_db).fetchRange(start, end);
      final expenseById = {for (final row in expenses) row.reference: row};

      final activityByDay = <int, List<AccountBookActivity>>{};
      void add(AccountBookActivity activity) {
        activityByDay.putIfAbsent(activity.date.day, () => []).add(activity);
      }

      for (final entry in money.entries) {
        final expense = expenseById[entry.transactionId];
        add(AccountBookActivity(
          date: entry.date,
          type: AccountBookActivityType.money,
          title: expense?.category ?? _label(entry.category),
          reference: entry.transactionId,
          detail: [
            entry.partyName,
            expense?.description,
            entry.accountName,
            entry.paymentMode,
            entry.referenceId,
          ]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join('  •  '),
          amount: entry.amount,
          incoming: entry.incoming,
          isCash: entry.isCash,
          isInternalTransfer: entry.isInternalTransfer,
        ));
      }
      for (final addition in money.bankOpeningAdditionsByDay.entries) {
        add(AccountBookActivity(
          date: addition.key,
          type: AccountBookActivityType.balance,
          title: 'Bank account opening balance',
          reference: 'Account activation',
          detail: 'Added to bank balance; excluded from receipts',
          amount: addition.value,
        ));
      }
      for (final document in documents) {
        add(AccountBookActivity(
          date: document.date,
          type: AccountBookActivityType.document,
          title: document.kind.label,
          reference: document.number,
          detail: [document.partyName, document.status]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join('  •  '),
          amount: document.amount,
        ));
      }
      for (final movement in movements) {
        add(AccountBookActivity(
          date: movement.occurredAt,
          type: AccountBookActivityType.stock,
          title:
              '${movement.isInward ? 'Stock In' : 'Stock Out'} · ${movement.itemName}',
          reference: movement.sourceNumber ??
              '${movement.sourceType} ${movement.sourceId}',
          detail:
              '${movement.metal}  •  ${movement.quantityDelta.abs()} pcs  •  '
              '${movement.netWeightDelta.abs().toStringAsFixed(3)} g',
        ));
      }

      // Girvi events are read by date so interest and releases retain their
      // original Day Book grouping and dates.
      final activityRepository = DayBookActivityRepository(_db);
      final activeGirviDays = <DateTime>{};
      final releases = await (_db.select(_db.girviLoans)
            ..where((loan) =>
                loan.releaseDate.isBiggerOrEqualValue(start) &
                loan.releaseDate.isSmallerThanValue(end)))
          .get();
      for (final loan in releases) {
        if (loan.releaseDate != null) {
          activeGirviDays.add(_date(loan.releaseDate!));
        }
      }
      final payments = await (_db.select(_db.girviPayments)
            ..where((payment) =>
                payment.paymentDate.isBiggerOrEqualValue(start) &
                payment.paymentDate.isSmallerThanValue(end)))
          .get();
      for (final payment in payments) {
        activeGirviDays.add(_date(payment.paymentDate));
      }
      final melts = await (_db.select(_db.girviLoanItems)
            ..where((item) =>
                item.recoveryDisposedAt.isBiggerOrEqualValue(start) &
                item.recoveryDisposedAt.isSmallerThanValue(end)))
          .get();
      for (final item in melts) {
        if (item.recoveryDisposedAt != null) {
          activeGirviDays.add(_date(item.recoveryDisposedAt!));
        }
      }
      for (final day in activeGirviDays) {
        final events = await activityRepository.fetch(day);
        for (final event in events) {
          add(AccountBookActivity(
            date: event.date,
            type: AccountBookActivityType.girvi,
            title: switch (event.kind.name) {
              'girviRelease' => 'Girvi Released',
              'girviInterest' => 'Girvi Interest',
              'girviMelted' => 'Girvi Melted',
              _ => 'Due Collection',
            },
            reference: event.number,
            detail: event.partyName,
            amount: event.amount > 0 ? event.amount : null,
          ));
        }
      }

      // A ledger snapshot covers the complete calendar month, including days
      // without transactions. Each day's opening is the previous day's close.
      final entriesByDay = <int, List<DayBookMoneyEntry>>{};
      for (final entry in money.entries) {
        entriesByDay.putIfAbsent(entry.date.day, () => []).add(entry);
      }
      var cash = money.openingCash;
      var bank = money.openingBank;
      final days = <AccountBookDay>[];
      for (var day = start;
          day.isBefore(end);
          day = DateTime(day.year, day.month, day.day + 1)) {
        final entries = entriesByDay[day.day] ?? const <DayBookMoneyEntry>[];
        double sum(bool isCash, bool incoming) => entries
            .where(
                (entry) => entry.isCash == isCash && entry.incoming == incoming)
            .fold(0, (double value, entry) => value + entry.amount);
        final activities = activityByDay[day.day] ?? [];
        activities.sort((a, b) {
          final result = a.date.compareTo(b.date);
          return result != 0 ? result : a.reference.compareTo(b.reference);
        });
        final record = AccountBookDay(
          date: day,
          activities: List.unmodifiable(activities),
          openingCash: cash,
          openingBank: bank,
          cashIn: sum(true, true),
          cashOut: sum(true, false),
          bankIn: sum(false, true),
          bankOut: sum(false, false),
          bankOpeningAdditions: money.bankOpeningAdditionsByDay[day] ?? 0,
        );
        days.add(record);
        cash = record.closingCash;
        bank = record.closingBank;
      }
      if ((cash - money.closingCash).abs() > 0.01 ||
          (bank - money.closingBank).abs() > 0.01) {
        throw StateError('Monthly ledger does not reconcile with Day Book.');
      }
      return AccountBookMonth(
        month: start,
        money: money,
        days: List.unmodifiable(days),
      );
    });
  }

  static String _label(String value) => value
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0]}${word.substring(1).toLowerCase()}')
      .join(' ');

  static DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
