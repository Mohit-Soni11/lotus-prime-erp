import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_document.dart';

class DayBookDocumentRepository {
  const DayBookDocumentRepository(this._db);

  final AppDatabase _db;

  Future<List<DayBookDocument>> fetch(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final documents = <DayBookDocument>[];

    final bills = await (_db.select(_db.bills)
          ..where((bill) =>
              bill.billDate.isBiggerOrEqualValue(start) &
              bill.billDate.isSmallerThanValue(end)))
        .get();
    for (final bill in bills) {
      if (!const {'ACTIVE', 'PARTIALLY_RETURNED', 'RETURNED'}
          .contains(bill.status.toUpperCase())) {
        continue;
      }
      final isGst = bill.billType.toUpperCase() == 'GST' ||
          bill.gstAmount > 0.005 ||
          bill.billNo.startsWith('TAX-');
      documents.add(DayBookDocument(
        kind: isGst
            ? DayBookDocumentKind.gstInvoice
            : DayBookDocumentKind.regularInvoice,
        sourceId: bill.id.toString(),
        number: bill.billNo,
        date: bill.billDate,
        amount: bill.finalAmount,
        tax: bill.cgstAmount + bill.sgstAmount + bill.igstAmount,
        status: bill.status,
      ));
    }

    final advances = await (_db.select(_db.orderAdvances)
          ..where((advance) =>
              advance.paymentDate.isBiggerOrEqualValue(start) &
              advance.paymentDate.isSmallerThanValue(end)))
        .get();
    for (final advance in advances) {
      documents.add(DayBookDocument(
        kind: DayBookDocumentKind.advanceReceipt,
        sourceId: advance.id.toString(),
        number: 'Order ${advance.orderId} / Receipt ${advance.id}',
        date: advance.paymentDate,
        amount: advance.amountPaid,
        collection: advance.amountPaid,
        status: 'POSTED',
      ));
    }

    final loans = await (_db.select(_db.girviLoans)
          ..where((loan) =>
              loan.startDate.isBiggerOrEqualValue(start) &
              loan.startDate.isSmallerThanValue(end)))
        .get();
    for (final loan in loans) {
      documents.add(DayBookDocument(
        kind: DayBookDocumentKind.girviTicket,
        sourceId: loan.id.toString(),
        number: loan.ticketNo,
        date: loan.startDate,
        amount: loan.loanAmount,
        status: loan.status,
      ));
    }

    documents.addAll(await _rawDocuments(
      start,
      end,
      table: 'purchase_vouchers',
      kind: DayBookDocumentKind.purchaseVoucher,
      numberColumn: 'voucher_no',
      amountColumn: 'grand_total',
      taxColumn: 'gst_amount',
      collectionColumn: 'total_paid',
      outstandingColumn: 'balance_due',
    ));
    documents.addAll(await _rawDocuments(
      start,
      end,
      table: 'return_vouchers',
      kind: DayBookDocumentKind.returnVoucher,
      numberColumn: 'voucher_no',
      amountColumn: 'return_value',
      outstandingColumn: 'refund_payable_amount',
    ));
    documents.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate == 0 ? a.number.compareTo(b.number) : byDate;
    });
    return List.unmodifiable(documents);
  }

  Future<List<DayBookDocument>> _rawDocuments(
    DateTime start,
    DateTime end, {
    required String table,
    required DayBookDocumentKind kind,
    required String numberColumn,
    required String amountColumn,
    String? taxColumn,
    String? collectionColumn,
    String? outstandingColumn,
  }) async {
    final rows = await _db.customSelect(
      '''SELECT id, $numberColumn AS number, $amountColumn AS amount,
                ${taxColumn ?? 'NULL'} AS tax,
                ${collectionColumn ?? 'NULL'} AS collection,
                ${outstandingColumn ?? 'NULL'} AS outstanding,
                status, created_at
         FROM $table
         WHERE (created_at >= ? AND created_at < ?)
            OR (created_at >= ? AND created_at < ?)''',
      variables: [
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(end.millisecondsSinceEpoch),
        Variable.withInt(start.millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
      ],
    ).get();
    return [
      for (final row in rows)
        DayBookDocument(
          kind: kind,
          sourceId: row.read<int>('id').toString(),
          number: row.read<String>('number'),
          date: _date(row.read<int>('created_at')),
          amount: row.read<double>('amount'),
          tax: row.readNullable<double>('tax'),
          collection: row.readNullable<double>('collection'),
          outstanding: row.readNullable<double>('outstanding'),
          status: row.read<String>('status'),
        ),
    ];
  }

  DateTime _date(int timestamp) => DateTime.fromMillisecondsSinceEpoch(
      timestamp.abs() >= 100000000000 ? timestamp : timestamp * 1000);
}
