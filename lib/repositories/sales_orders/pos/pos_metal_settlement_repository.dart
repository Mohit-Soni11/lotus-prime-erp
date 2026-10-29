import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

/// Stores the issued, metal-specific financial snapshot with its bill.
class PosMetalSettlementRepository {
  const PosMetalSettlementRepository(this.database);

  final AppDatabase database;

  Future<void> ensureSchema() => database.ensureSalesMetalSettlementSchema();

  /// Called from the checkout transaction so bill and allocations commit together.
  Future<void> replace(
    int billId,
    List<PosInvoiceMetalPaymentAllocation> allocations,
  ) async {
    await database.customStatement(
      'DELETE FROM bill_metal_payment_allocations WHERE bill_id = ?',
      [billId],
    );
    for (final allocation in allocations) {
      await database.customStatement('''
        INSERT INTO bill_metal_payment_allocations (
          bill_id, metal, gross_amount, discount_amount, gst_amount, net_payable,
          cash_paid, upi_paid, card_paid, advance_paid, settle_first
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        billId,
        allocation.metal.name,
        allocation.grossAmount,
        allocation.discountAmount,
        allocation.gstAmount,
        allocation.netPayable,
        allocation.cashPaid,
        allocation.upiPaid,
        allocation.cardPaid,
        allocation.advancePaid,
        allocation.settleFirst ? 1 : 0,
      ]);
    }
  }

  Future<List<PosInvoiceMetalPaymentAllocation>> load(int billId) async {
    await ensureSchema();
    final rows = await database.customSelect(
      'SELECT * FROM bill_metal_payment_allocations WHERE bill_id = ?',
      variables: [Variable.withInt(billId)],
    ).get();
    return [
      for (final row in rows)
        PosInvoiceMetalPaymentAllocation(
          metal: MetalType.values.byName(row.read<String>('metal')),
          grossAmount: row.read<double>('gross_amount'),
          discountAmount: row.read<double>('discount_amount'),
          gstAmount: row.read<double>('gst_amount'),
          netPayable: row.read<double>('net_payable'),
          cashPaid: row.read<double>('cash_paid'),
          upiPaid: row.read<double>('upi_paid'),
          cardPaid: row.read<double>('card_paid'),
          advancePaid: row.read<double>('advance_paid'),
          settleFirst: row.read<int>('settle_first') == 1,
        ),
    ];
  }
}
