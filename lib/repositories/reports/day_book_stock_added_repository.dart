import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_stock_added_batch.dart';
import '../../models/purchase/purchase_voucher_origin.dart';

class DayBookStockAddedRepository {
  const DayBookStockAddedRepository(this._db);

  final AppDatabase _db;

  Future<List<DayBookStockAddedBatch>> fetch(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final rows = await _db.customSelect(
      '''
      SELECT sm.id AS movement_id, sm.source_line_no, sm.occurred_at,
             sm.quantity_delta, sm.net_weight_delta,
             sm.metal_type_snapshot,
             pv.id AS voucher_id, pv.voucher_no, pv.grand_total,
             pvi.metal_type, pvi.rate, pvi.making_total
      FROM stock_movements sm
      JOIN purchase_vouchers pv ON CAST(pv.id AS TEXT) = sm.source_id
      LEFT JOIN purchase_voucher_items pvi
        ON pvi.purchase_voucher_id = pv.id
       AND pvi.line_no = sm.source_line_no
      WHERE sm.movement_type = 'IN'
        AND sm.source_type = 'PURCHASE'
        AND pv.entry_origin = ?
        AND UPPER(pv.source_type) = 'SUPPLIER'
        AND UPPER(pv.status) NOT IN ('VOID', 'VOIDED', 'CANCELLED')
        AND ((sm.occurred_at >= ? AND sm.occurred_at < ?)
          OR (sm.occurred_at >= ? AND sm.occurred_at < ?))
      ORDER BY sm.occurred_at, sm.id
      ''',
      variables: [
        Variable.withString(PurchaseVoucherOrigin.addStock.storageValue),
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(end.millisecondsSinceEpoch),
        Variable.withInt(start.millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {_db.stockMovements},
    ).get();

    final batches = <int, _BatchAccumulator>{};
    for (final row in rows) {
      final voucherId = row.read<int>('voucher_id');
      final batch = batches.putIfAbsent(
        voucherId,
        () => _BatchAccumulator(
          voucherId: voucherId,
          batchCode: row.read<String>('voucher_no'),
          purchaseValue: row.read<double>('grand_total'),
        ),
      );
      batch.add(row);
    }
    return List.unmodifiable(batches.values.map((batch) => batch.build()));
  }
}

class _BatchAccumulator {
  _BatchAccumulator({
    required this.voucherId,
    required this.batchCode,
    required this.purchaseValue,
  });

  final int voucherId;
  final String batchCode;
  final double purchaseValue;
  final Set<int> _lineNumbers = {};
  final Set<String> _metals = {};
  final Set<double> _rates = {};
  DateTime? _postedAt;
  int _pieces = 0;
  double _netWeight = 0;
  double _making = 0;
  bool _makingKnown = true;
  bool _rateKnown = true;

  void add(QueryRow row) {
    final lineNo = row.readNullable<int>('source_line_no');
    if (lineNo != null && !_lineNumbers.add(lineNo)) {
      throw StateError('Duplicate stock posting for $batchCode line $lineNo.');
    }
    final timestamp = row.read<int>('occurred_at');
    _postedAt ??= DateTime.fromMillisecondsSinceEpoch(
      timestamp.abs() >= 100000000000 ? timestamp : timestamp * 1000,
    );
    _pieces += row.read<int>('quantity_delta');
    _netWeight += row.read<double>('net_weight_delta');
    final metal = (row.readNullable<String>('metal_type') ??
            row.read<String>('metal_type_snapshot'))
        .trim();
    if (metal.isNotEmpty) _metals.add(metal);
    final rate = row.readNullable<double>('rate');
    if (rate == null || rate <= 0) {
      _rateKnown = false;
    } else {
      _rates.add(rate);
    }
    final making = row.readNullable<double>('making_total');
    if (making == null) {
      _makingKnown = false;
    } else {
      _making += making;
    }
  }

  DayBookStockAddedBatch build() => DayBookStockAddedBatch(
        voucherId: voucherId,
        batchCode: batchCode,
        metal: _metals.length == 1 ? _metals.single : 'Mixed',
        postedAt: _postedAt!,
        pieces: _pieces,
        netWeightGrams: _netWeight,
        ratePerGram: _rateKnown && _rates.length == 1 ? _rates.single : null,
        hasMixedRates: _rates.length > 1,
        makingTotal: _makingKnown ? _making : null,
        purchaseValue: purchaseValue,
      );
}
