import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';

void main() {
  test('untracked stock intake is not presented as paid or unpaid', () {
    final purchase = SupplierProfilePurchaseModel(
      voucherId: 1,
      voucherNo: 'STOCK-1',
      partyName: 'Supplier',
      grossAmount: 1000,
      grandTotal: 1000,
      totalPaid: 0,
      balanceDue: 0,
      ratePerKg: 1000,
      metalPaidGrossWeight: 0,
      metalPaidPurity: 0,
      metalPaidFine: 0,
      metalPaidValue: 0,
      paymentStatus: 'NOT_TRACKED',
      stockEntryCount: 1,
      createdAt: DateTime(2026),
    );

    expect(purchase.isSettlementTracked, isFalse);
    expect(purchase.statusLabel, 'STOCK INTAKE');
  });
}
