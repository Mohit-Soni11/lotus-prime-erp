import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';

void main() {
  test('return melting voucher status is shown as paid payout', () {
    final entry = _entry(
      paymentStatus: 'RETURN_MELTING',
      isTransferredToMelting: true,
      transferredToMeltingAt: DateTime(2026, 9, 12),
      meltingBatchNo: 'CMB-GOLD-20260912-120000',
    );

    expect(entry.metalFlowStatusLabel, 'Melted & Closed');
    expect(entry.payoutStatusLabel, 'Paid');
  });

  test('pending amount controls seller payout status', () {
    expect(
      _entry(
        paymentStatus: 'RETURN_MELTING',
        paidAmount: 5000,
        pendingAmount: 2500,
      ).payoutStatusLabel,
      'Part Paid',
    );
    expect(
      _entry(
        paymentStatus: 'RETURN_MELTING',
        paidAmount: 0,
        pendingAmount: 2500,
      ).payoutStatusLabel,
      'Payout Pending',
    );
  });
}

CustomerMetalPurchaseEntry _entry({
  String paymentStatus = 'PAID',
  double paidAmount = 10000,
  double pendingAmount = 0,
  bool isTransferredToMelting = false,
  DateTime? transferredToMeltingAt,
  String? meltingBatchNo,
}) {
  return CustomerMetalPurchaseEntry(
    id: 1,
    customerId: 1,
    sourceDocumentId: 1,
    date: DateTime(2026, 9, 12),
    source: 'direct',
    referenceNo: 'AJ-PUR-2026-0001',
    customerName: 'REYANSH SONI',
    metalType: 'GOLD',
    itemDescription: 'Old gold',
    grossWeight: 10,
    netWeight: 9,
    purity: 91.6,
    fineWeight: 8.244,
    rate: 7400,
    amount: 10000,
    paidAmount: paidAmount,
    pendingAmount: pendingAmount,
    paymentStatus: paymentStatus,
    isTransferredToMelting: isTransferredToMelting,
    transferredToMeltingAt: transferredToMeltingAt,
    meltingBatchNo: meltingBatchNo,
  );
}
