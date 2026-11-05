import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_activity_event.dart';
import '../../models/reports/day_book/day_book_money_flow.dart';
import '../../models/reports/day_book/day_book_document_item.dart';

/// Reads dated business events; it never posts money or owned stock.
class DayBookActivityRepository {
  const DayBookActivityRepository(this._db);

  final AppDatabase _db;

  Future<List<DayBookActivityEvent>> fetch(
    DateTime date, {
    DayBookMoneyFlow? moneyFlow,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final events = <DayBookActivityEvent>[];

    final released = await (_db.select(_db.girviLoans)
          ..where((loan) =>
              loan.releaseDate.isBiggerOrEqualValue(start) &
              loan.releaseDate.isSmallerThanValue(end) &
              loan.status.isIn(const ['RELEASED', 'READY_FOR_DELIVERY'])))
        .get();
    final dayPayments = await (_db.select(_db.girviPayments)
          ..where((payment) =>
              payment.paymentDate.isBiggerOrEqualValue(start) &
              payment.paymentDate.isSmallerThanValue(end)))
        .get();
    final settledToday = <int, double>{};
    final interestToday = <int, double>{};
    final interestAt = <int, DateTime>{};
    for (final payment in dayPayments) {
      final type = payment.paymentType.toUpperCase();
      if (type == 'FULL_RELEASE') {
        settledToday[payment.girviId] =
            (settledToday[payment.girviId] ?? 0) + payment.amount;
      }
      final interest = payment.interestComponent > 0
          ? payment.interestComponent
          : const {'INTEREST', 'PARTIAL_INTEREST'}.contains(type)
              ? payment.amount
              : 0.0;
      if (interest > 0) {
        interestToday[payment.girviId] =
            (interestToday[payment.girviId] ?? 0) + interest;
        final previous = interestAt[payment.girviId];
        if (previous == null || payment.paymentDate.isBefore(previous)) {
          interestAt[payment.girviId] = payment.paymentDate;
        }
      }
    }
    for (final loan in released) {
      events.add(DayBookActivityEvent(
        kind: DayBookActivityKind.girviRelease,
        sourceId: loan.id,
        number: loan.ticketNo,
        date: loan.releaseDate!,
        amount: settledToday[loan.id] ?? 0,
        customerId: loan.customerId,
        items: [_loanItem(loan)],
      ));
    }

    if (interestToday.isNotEmpty) {
      final loans = await (_db.select(_db.girviLoans)
            ..where((loan) => loan.id.isIn(interestToday.keys.toList())))
          .get();
      for (final loan in loans) {
        events.add(DayBookActivityEvent(
          kind: DayBookActivityKind.girviInterest,
          sourceId: loan.id,
          number: loan.ticketNo,
          date: interestAt[loan.id]!,
          amount: interestToday[loan.id]!,
          customerId: loan.customerId,
          items: [_loanItem(loan)],
        ));
      }
    }

    final meltedItems = await (_db.select(_db.girviLoanItems)
          ..where((item) =>
              item.recoveryDispositionStatus.equals('MELTED') &
              item.recoveryDisposedAt.isBiggerOrEqualValue(start) &
              item.recoveryDisposedAt.isSmallerThanValue(end)))
        .get();
    final meltedLoans = <int>{};
    for (final item in meltedItems) {
      meltedLoans.add(item.girviId);
    }
    final loansById = <int, GirviLoan>{};
    if (meltedLoans.isNotEmpty) {
      final loans = await (_db.select(_db.girviLoans)
            ..where((row) => row.id.isIn(meltedLoans.toList())))
          .get();
      for (final loan in loans) {
        loansById[loan.id] = loan;
      }
    }
    final emitted = <int>{};
    for (final item in meltedItems) {
      if (!emitted.add(item.girviId)) continue;
      final loan = loansById[item.girviId];
      if (loan == null) continue;
      events.add(DayBookActivityEvent(
        kind: DayBookActivityKind.girviMelted,
        sourceId: loan.id,
        number: loan.ticketNo,
        date: item.recoveryDisposedAt!,
        amount: 0,
        customerId: loan.customerId,
        items: [_loanItem(loan)],
      ));
    }
    if (moneyFlow != null) {
      final dueByBill = <String, double>{};
      final firstReceiptAt = <String, DateTime>{};
      for (final entry in moneyFlow.entries) {
        if (!entry.incoming ||
            entry.category.toUpperCase() != 'DUE_COLLECTION' ||
            entry.referenceType?.toUpperCase() != 'BILL') {
          continue;
        }
        final billNo = entry.referenceId?.split('#').first.trim();
        if (billNo == null || billNo.isEmpty) continue;
        dueByBill[billNo] = (dueByBill[billNo] ?? 0) + entry.amount;
        final previous = firstReceiptAt[billNo];
        if (previous == null || entry.date.isBefore(previous)) {
          firstReceiptAt[billNo] = entry.date;
        }
      }
      if (dueByBill.isNotEmpty) {
        final bills = await (_db.select(_db.bills)
              ..where((bill) => bill.billNo.isIn(dueByBill.keys.toList())))
            .get();
        final billsByNumber = {for (final bill in bills) bill.billNo: bill};
        for (final due in dueByBill.entries) {
          final bill = billsByNumber[due.key];
          events.add(DayBookActivityEvent(
            kind: DayBookActivityKind.dueCollection,
            sourceId: bill?.id ?? 0,
            number: due.key,
            date: firstReceiptAt[due.key]!,
            amount: due.value,
            customerId: bill?.customerId,
            partyName: bill?.customerName,
            mobile: bill?.mobile,
          ));
        }
      }
    }
    final customerIds = events
        .where((event) => event.customerId != null)
        .map((event) => event.customerId!)
        .toSet();
    if (customerIds.isNotEmpty) {
      final customers = await (_db.select(_db.customers)
            ..where((customer) => customer.id.isIn(customerIds)))
          .get();
      final byId = {for (final customer in customers) customer.id: customer};
      for (var index = 0; index < events.length; index++) {
        final event = events[index];
        final customer = byId[event.customerId];
        if (customer == null) continue;
        events[index] = event.withParty(
          name: event.partyName?.trim().isNotEmpty == true
              ? event.partyName
              : customer.name,
          phone: event.mobile?.trim().isNotEmpty == true
              ? event.mobile
              : customer.mobile,
        );
      }
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(events);
  }

  DayBookDocumentItem _loanItem(GirviLoan loan) => DayBookDocumentItem(
        metal: loan.metalType,
        name: loan.itemDescription,
        netWeightGrams: loan.netWeight,
        quantity: loan.itemCount,
      );
}
