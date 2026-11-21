import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/models/dashboard/daily_counter_model.dart';

class DailyCounterMetalRepository {
  final AppDatabase db;

  const DailyCounterMetalRepository(this.db);

  Future<MetalMovementData> load(DashboardDay day) async {
    final bills = await (db.select(db.bills)
          ..where((t) => t.billDate.isBiggerOrEqualValue(day.start))
          ..where((t) => t.billDate.isSmallerThanValue(day.end))
          ..where((t) => t.status.isIn(const [
                'ACTIVE',
                'PARTIALLY_RETURNED',
                'RETURNED',
              ])))
        .get();
    final billIds = bills.map((bill) => bill.id).toList();
    var soldGoldWeight = 0.0, soldSilverWeight = 0.0;
    var soldGoldPieces = 0, soldSilverPieces = 0;
    var oldGoldWeight = 0.0, oldSilverWeight = 0.0;
    var oldGoldPieces = 0, oldSilverPieces = 0;

    if (billIds.isNotEmpty) {
      final items = await (db.select(db.billItems)
            ..where((t) => t.billId.isIn(billIds)))
          .get();
      for (final item in items) {
        final metal = item.metalType.trim().toUpperCase();
        if (metal.contains('SILVER')) {
          soldSilverWeight += item.netWeight;
          soldSilverPieces += item.quantity;
        } else if (metal.contains('GOLD')) {
          soldGoldWeight += item.netWeight;
          soldGoldPieces += item.quantity;
        }
      }

      final returns = await _loadReturns(billIds);
      soldGoldWeight -= returns.goldWeight;
      soldGoldPieces -= returns.goldPieces;
      soldSilverWeight -= returns.silverWeight;
      soldSilverPieces -= returns.silverPieces;

      final tradeIns = await (db.select(db.billTradeInItems)
            ..where((t) => t.billId.isIn(billIds)))
          .get();
      for (final item in tradeIns) {
        final metal = item.metalType.trim().toUpperCase();
        if (metal.contains('SILVER')) {
          oldSilverWeight += item.netWeight;
          oldSilverPieces++;
        } else if (metal.contains('GOLD')) {
          oldGoldWeight += item.netWeight;
          oldGoldPieces++;
        }
      }
    }

    final purchases = await _loadCustomerPurchases(day);
    oldGoldWeight += purchases.goldWeight;
    oldGoldPieces += purchases.goldPieces;
    oldSilverWeight += purchases.silverWeight;
    oldSilverPieces += purchases.silverPieces;

    return MetalMovementData(
      soldGold:
          _entry(math.max(0, soldGoldWeight), math.max(0, soldGoldPieces)),
      soldSilver:
          _entry(math.max(0, soldSilverWeight), math.max(0, soldSilverPieces)),
      boughtGold: _entry(oldGoldWeight, oldGoldPieces),
      boughtSilver: _entry(oldSilverWeight, oldSilverPieces),
    );
  }

  Future<_MetalTotals> _loadReturns(List<int> billIds) async {
    await db.ensureReturnReversalSchema();
    final rows = await db.customSelect(
      '''SELECT l.metal_type,
                COALESCE(SUM(l.sold_net_weight), 0) AS weight,
                COALESCE(SUM(l.quantity), 0) AS pieces
         FROM return_voucher_lines l
         JOIN return_vouchers v ON v.id = l.return_voucher_id
         WHERE v.operation_type = 'SALES_RETURN'
           AND v.source_type = 'SALES_INVOICE'
           AND v.source_id IN (${List.filled(billIds.length, '?').join(',')})
           AND v.status <> 'VOIDED' AND l.status <> 'VOIDED'
         GROUP BY UPPER(TRIM(l.metal_type))''',
      variables: billIds.map(Variable.withInt).toList(),
    ).get();
    return _totals(rows);
  }

  Future<_MetalTotals> _loadCustomerPurchases(DashboardDay day) async {
    await db.ensureReturnReversalSchema();
    final rows = await db.customSelect(
      '''SELECT pvi.metal_type,
                COALESCE(SUM(pvi.net_weight), 0) AS weight,
                COALESCE(SUM(pvi.quantity), 0) AS pieces
         FROM purchase_voucher_items pvi
         JOIN purchase_vouchers pv ON pv.id = pvi.purchase_voucher_id
         WHERE pv.source_type = 'CUSTOMER'
           AND pv.status <> 'CANCELLED'
           AND pv.payment_status <> 'RETURN_MELTING'
           AND pv.voucher_no NOT LIKE 'MELT-%'
           AND pv.created_at >= ? AND pv.created_at < ?
         GROUP BY UPPER(TRIM(pvi.metal_type))''',
      variables: [
        Variable.withInt(day.start.millisecondsSinceEpoch),
        Variable.withInt(day.end.millisecondsSinceEpoch),
      ],
    ).get();
    return _totals(rows);
  }

  _MetalTotals _totals(List<QueryRow> rows) {
    var goldWeight = 0.0, silverWeight = 0.0;
    var goldPieces = 0, silverPieces = 0;
    for (final row in rows) {
      final metal = row.read<String>('metal_type').toUpperCase();
      final weight = row.read<double>('weight');
      final pieces = row.read<int>('pieces');
      if (metal.contains('SILVER')) {
        silverWeight += weight;
        silverPieces += pieces;
      } else if (metal.contains('GOLD')) {
        goldWeight += weight;
        goldPieces += pieces;
      }
    }
    return _MetalTotals(goldWeight, goldPieces, silverWeight, silverPieces);
  }

  MetalEntry _entry(double weight, int pieces) => MetalEntry(
        weightStr: '${weight.toStringAsFixed(3)} gm',
        piecesStr: pieces == 1 ? '1 Pc' : '$pieces Pcs',
        weightRaw: weight,
        piecesRaw: pieces,
      );
}

class _MetalTotals {
  final double goldWeight;
  final int goldPieces;
  final double silverWeight;
  final int silverPieces;

  const _MetalTotals(
      this.goldWeight, this.goldPieces, this.silverWeight, this.silverPieces);
}
