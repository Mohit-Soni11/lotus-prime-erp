import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_custody_position.dart';

class DayBookCustodyRepository {
  const DayBookCustodyRepository(this._db);

  final AppDatabase _db;

  Future<DayBookCustodyPosition> fetch(DateTime date) async {
    final end = DateTime(date.year, date.month, date.day + 1);
    final loans = await (_db.select(_db.girviLoans)
          ..where((loan) => loan.startDate.isSmallerThanValue(end)))
        .get();
    final itemsByLoan = <int, List<GirviLoanItem>>{};
    for (var offset = 0; offset < loans.length; offset += 500) {
      final ids = loans.skip(offset).take(500).map((loan) => loan.id).toList();
      final items = await (_db.select(_db.girviLoanItems)
            ..where((item) => item.girviId.isIn(ids)))
          .get();
      for (final item in items) {
        itemsByLoan.putIfAbsent(item.girviId, () => []).add(item);
      }
    }

    final lines = <DayBookCustodyLine>[];
    for (final loan in loans) {
      final items = itemsByLoan[loan.id];
      if (items == null || items.isEmpty) {
        final uncertainFrom =
            loan.deliveredAt == null && _closedStatus(loan.status)
                ? loan.releaseDate ?? loan.startDate
                : null;
        lines.add(DayBookCustodyLine(
          ticketNo: loan.ticketNo,
          itemName: loan.itemDescription,
          metal: loan.metalType,
          purity: loan.metalPurity,
          pieces: loan.itemCount,
          grossWeight: loan.grossWeight,
          netWeight: loan.netWeight,
          receivedAt: loan.startDate,
          exitedAt: loan.deliveredAt,
          uncertainFrom: uncertainFrom,
          isLegacy: true,
        ));
        continue;
      }
      for (final item in items) {
        final recovery = item.recoveryDisposedAt;
        final delivery = loan.deliveredAt;
        final exit = recovery == null
            ? delivery
            : delivery == null || recovery.isBefore(delivery)
                ? recovery
                : delivery;
        final uncertainFrom = exit == null && _closedStatus(loan.status)
            ? loan.releaseDate ?? loan.startDate
            : null;
        lines.add(DayBookCustodyLine(
          ticketNo: loan.ticketNo,
          itemName: item.itemName,
          metal: item.metalType,
          purity: item.purity,
          pieces: item.pieces,
          grossWeight: item.grossWeight,
          netWeight: item.netWeight,
          fineWeight: item.purityFactor > 0 && item.purityFactor <= 1
              ? item.netWeight * item.purityFactor
              : null,
          receivedAt: loan.startDate,
          exitedAt: exit,
          uncertainFrom: uncertainFrom,
          isLegacy: item.isLegacy,
        ));
      }
    }
    return DayBookCustodyPosition(date, lines);
  }

  bool _closedStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'RELEASED' || normalized == 'AUCTIONED';
  }
}
