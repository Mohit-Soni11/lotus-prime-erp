import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/due_report/due_report_model.dart';

class DueReportRepository {
  final AppDatabase _db;

  DueReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<DueBillModel>> fetchDueBills() async {
    try {
      final rows = await _baseQuery().get();
      return _mapRows(rows);
    } catch (e) {
      debugPrint('DueReportRepository.fetchDueBills error: $e');
      return [];
    }
  }

  Stream<List<DueBillModel>> watchDueBills() {
    return _baseQuery().watch().map<List<DueBillModel>>(
          (rows) => _mapRows(rows.cast<TypedResult>()),
        );
  }

  _baseQuery() {
    final query = _db.select(_db.bills).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.bills.customerId),
      ),
    ])
      ..where(_db.bills.status.equals('ACTIVE'))
      ..orderBy([OrderingTerm.desc(_db.bills.billDate)]);
    return query;
  }

  List<DueBillModel> _mapRows(List<TypedResult> rows) {
    final List<DueBillModel> bills = [];

    for (final row in rows) {
      final bill = row.readTable(_db.bills);
      final customer = row.readTableOrNull(_db.customers);

      final computedDue = _positive(bill.finalAmount - bill.paidAmount);
      final dueAmount = bill.dueAmount > 0.5 ? bill.dueAmount : computedDue;
      if (dueAmount <= 0.5) continue;

      final customerName = _firstText([
        customer?.name,
        bill.customerName,
        'Walk-in Customer',
      ]);
      final mobile = _firstText([customer?.mobile, bill.mobile, '-']);
      final city = _firstText([customer?.city, '']);

      bills.add(
        DueBillModel(
          id: bill.id,
          billNo: bill.billNo,
          customerId: bill.customerId,
          customerName: customerName,
          mobile: mobile,
          city: city,
          address: _addressFor(customer, city),
          billDate: bill.billDate,
          promiseDate: bill.promiseDate,
          finalAmount: bill.finalAmount,
          paidAmount: bill.paidAmount,
          dueAmount: dueAmount,
          paymentStatus: bill.paymentStatus,
          billingMode: bill.billingMode,
          billType: bill.billType,
        ),
      );
    }

    bills.sort((a, b) {
      final promiseCompare = _promiseSortValue(
        a,
      ).compareTo(_promiseSortValue(b));
      if (promiseCompare != 0) return promiseCompare;
      return b.dueAmount.compareTo(a.dueAmount);
    });

    return bills;
  }

  int _promiseSortValue(DueBillModel bill) {
    if (bill.promiseDate == null) return 999999999;
    return bill.promiseDate!.millisecondsSinceEpoch;
  }

  double _positive(double amount) => amount < 0 ? 0 : amount;

  String _addressFor(Customer? customer, String city) {
    if (customer == null) return city;
    final parts = [
      customer.addressLine1,
      customer.addressLine2,
      customer.city,
      customer.state,
      customer.pincode,
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.isEmpty ? city : parts.join(', ');
  }

  String _firstText(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '-';
  }
}
