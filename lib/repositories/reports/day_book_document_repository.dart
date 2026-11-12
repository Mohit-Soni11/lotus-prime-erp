import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_document.dart';
import '../../models/reports/day_book/day_book_document_item.dart';
import 'day_book_bill_issue_snapshot_repository.dart';

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
    final issueSnapshots = await DayBookBillIssueSnapshotRepository(_db)
        .fetchForBills(bills.map((bill) => bill.id));
    final billItems = bills.isEmpty
        ? <BillItem>[]
        : await (_db.select(_db.billItems)
              ..where((item) => item.billId.isIn(bills.map((b) => b.id))))
            .get();
    final itemsByBill = <int, List<DayBookDocumentItem>>{};
    for (final item in billItems) {
      itemsByBill.putIfAbsent(item.billId, () => []).add(DayBookDocumentItem(
            metal: item.metalType,
            name: item.itemName,
            netWeightGrams: item.netWeight,
            quantity: item.quantity,
          ));
    }
    for (final bill in bills) {
      final issue = issueSnapshots[bill.id];
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
        amount: issue?.finalAmount ?? bill.finalAmount,
        tax: issue == null
            ? bill.cgstAmount + bill.sgstAmount + bill.igstAmount
            : issue.cgst + issue.sgst + issue.igst,
        outstanding: issue?.issuedDue,
        status: bill.status,
        customerId: bill.customerId,
        partyName: bill.customerName,
        mobile: bill.mobile,
        items: List.unmodifiable(itemsByBill[bill.id] ?? const []),
        savedPaid: bill.paidAmount,
        savedDue: bill.dueAmount,
        issueSnapshotAvailable: issue != null,
      ));
    }

    final advances = await (_db.select(_db.orderAdvances)
          ..where((advance) =>
              advance.paymentDate.isBiggerOrEqualValue(start) &
              advance.paymentDate.isSmallerThanValue(end)))
        .get();
    final advanceOrders = <int, SalesOrder>{};
    if (advances.isNotEmpty) {
      final orders = await (_db.select(_db.salesOrders)
            ..where((row) => row.id
                .isIn(advances.map((advance) => advance.orderId).toList())))
          .get();
      for (final order in orders) {
        advanceOrders[order.id] = order;
      }
    }
    for (final advance in advances) {
      final order = advanceOrders[advance.orderId];
      documents.add(DayBookDocument(
        kind: DayBookDocumentKind.advanceReceipt,
        sourceId: advance.id.toString(),
        number:
            '${order?.orderNo ?? 'Order ${advance.orderId}'} / Receipt ${advance.id}',
        date: advance.paymentDate,
        amount: advance.amountPaid,
        // A booking advance may include old metal credit, which is not money in.
        // The collection mapper matches only posted cash and bank receipts.
        collection: null,
        status: 'POSTED',
        customerId: order?.customerId,
        relatedEntityId: advance.orderId,
        items: order == null
            ? const []
            : [
                DayBookDocumentItem(
                  metal: order.metalType,
                  name: order.itemName,
                  netWeightGrams: order.approxWeight,
                ),
              ],
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
        customerId: loan.customerId,
        items: [
          DayBookDocumentItem(
            metal: loan.metalType,
            name: loan.itemDescription,
            netWeightGrams: loan.netWeight,
            quantity: loan.itemCount,
          ),
        ],
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
      sourceTypeColumn: 'source_type',
      supplierIdColumn: 'supplier_id',
      partyNameColumn: 'party_name',
      mobileColumn: 'mobile',
    ));
    documents.addAll(await _rawDocuments(
      start,
      end,
      table: 'return_vouchers',
      kind: DayBookDocumentKind.returnVoucher,
      numberColumn: 'voucher_no',
      amountColumn: 'return_value',
      outstandingColumn: 'refund_payable_amount',
      sourceTypeColumn: 'source_type',
      originalSourceIdColumn: 'source_id',
      partyNameColumn: 'customer_name',
      mobileColumn: 'mobile',
    ));
    final customerIds = documents
        .where((document) => document.customerId != null)
        .map((document) => document.customerId!)
        .toSet();
    if (customerIds.isNotEmpty) {
      final customers = await (_db.select(_db.customers)
            ..where((customer) => customer.id.isIn(customerIds)))
          .get();
      final byId = {for (final customer in customers) customer.id: customer};
      for (var index = 0; index < documents.length; index++) {
        final source = documents[index];
        final customer = byId[source.customerId];
        if (customer == null) continue;
        documents[index] = source.withParty(
          name: source.partyName?.trim().isNotEmpty == true
              ? source.partyName
              : customer.name,
          phone: source.mobile?.trim().isNotEmpty == true
              ? source.mobile
              : customer.mobile,
        );
      }
    }
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
    String? sourceTypeColumn,
    String? supplierIdColumn,
    String? originalSourceIdColumn,
    String? partyNameColumn,
    String? mobileColumn,
  }) async {
    final rows = await _db.customSelect(
      '''SELECT id, $numberColumn AS number, $amountColumn AS amount,
                ${taxColumn ?? 'NULL'} AS tax,
                ${collectionColumn ?? 'NULL'} AS collection,
                ${outstandingColumn ?? 'NULL'} AS outstanding,
                customer_id, ${sourceTypeColumn ?? 'NULL'} AS source_type,
                ${supplierIdColumn ?? 'NULL'} AS supplier_id,
                ${originalSourceIdColumn ?? 'NULL'} AS original_source_id,
                ${partyNameColumn ?? 'NULL'} AS party_name,
                ${mobileColumn ?? 'NULL'} AS mobile,
                ${kind == DayBookDocumentKind.returnVoucher ? 'operation_type' : 'NULL'} AS operation_type,
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
    final itemsByVoucher = await _rawItems(
      kind,
      rows.map((row) => row.read<int>('id')).toList(),
    );
    return [
      for (final row in rows)
        DayBookDocument(
          kind: kind == DayBookDocumentKind.returnVoucher &&
                  row.readNullable<String>('operation_type')?.toUpperCase() ==
                      'BOOKING_CANCELLATION'
              ? DayBookDocumentKind.advanceCancellationVoucher
              : kind,
          sourceId: row.read<int>('id').toString(),
          number: row.read<String>('number'),
          date: _date(row.read<int>('created_at')),
          amount: row.read<double>('amount'),
          tax: row.readNullable<double>('tax'),
          collection: row.readNullable<double>('collection'),
          outstanding: row.readNullable<double>('outstanding'),
          status: row.read<String>('status'),
          customerId: row.readNullable<int>('customer_id'),
          supplierId: row.readNullable<int>('supplier_id'),
          sourceType: row.readNullable<String>('source_type'),
          originalSourceId: row.readNullable<int>('original_source_id'),
          partyName: row.readNullable<String>('party_name'),
          mobile: row.readNullable<String>('mobile'),
          items: itemsByVoucher[row.read<int>('id')] ?? const [],
          savedPaid: row.readNullable<double>('collection'),
          savedDue: row.readNullable<double>('outstanding'),
        ),
    ];
  }

  Future<Map<int, List<DayBookDocumentItem>>> _rawItems(
      DayBookDocumentKind kind, List<int> ids) async {
    if (ids.isEmpty) return const {};
    final isPurchase = kind == DayBookDocumentKind.purchaseVoucher;
    if (!isPurchase && kind != DayBookDocumentKind.returnVoucher) {
      return const {};
    }
    final table =
        isPurchase ? 'purchase_voucher_items' : 'return_voucher_lines';
    final owner = isPurchase ? 'purchase_voucher_id' : 'return_voucher_id';
    final name = isPurchase ? 'item_description' : 'item_description';
    final weight = isPurchase ? 'net_weight' : 'received_net_weight';
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db
        .customSelect(
          'SELECT $owner AS voucher_id, metal_type, $name AS item_name, '
          '$weight AS net_weight, quantity FROM $table '
          'WHERE $owner IN ($placeholders) ORDER BY $owner, id',
          variables: ids.map(Variable.withInt).toList(),
        )
        .get();
    final result = <int, List<DayBookDocumentItem>>{};
    for (final row in rows) {
      final id = row.read<int>('voucher_id');
      result.putIfAbsent(id, () => []).add(DayBookDocumentItem(
            metal: row.read<String>('metal_type'),
            name: row.readNullable<String>('item_name') ?? 'Metal item',
            netWeightGrams: row.read<double>('net_weight'),
            quantity: row.read<int>('quantity'),
          ));
    }
    return result.map((id, items) => MapEntry(id, List.unmodifiable(items)));
  }

  DateTime _date(int timestamp) => DateTime.fromMillisecondsSinceEpoch(
      timestamp.abs() >= 100000000000 ? timestamp : timestamp * 1000);
}
