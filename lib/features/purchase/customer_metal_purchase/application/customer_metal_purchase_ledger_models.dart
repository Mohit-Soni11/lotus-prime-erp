import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';

enum CustomerMetalPurchaseMetal {
  gold('Gold', 'GOLD'),
  silver('Silver', 'SILVER'),
  diamond('Diamond', 'DIAMOND'),
  platinum('Platinum', 'PLATINUM');

  final String label;
  final String storageValue;

  const CustomerMetalPurchaseMetal(this.label, this.storageValue);
}

class CustomerMetalPurchaseMetalSummary {
  final CustomerMetalPurchaseMetal metal;
  final double grossWeight;
  final double fineWeight;
  final double amount;
  final int entryCount;
  final int directPurchaseCount;
  final int tradeInCount;
  final int refundCount;

  const CustomerMetalPurchaseMetalSummary({
    required this.metal,
    required this.grossWeight,
    required this.fineWeight,
    required this.amount,
    required this.entryCount,
    required this.directPurchaseCount,
    required this.tradeInCount,
    required this.refundCount,
  });

  double get averagePurchaseRate => fineWeight <= 0 ? 0 : amount / fineWeight;
}

CustomerMetalPurchaseMetalSummary buildCustomerMetalPurchaseSummary({
  required CustomerMetalPurchaseMetal metal,
  required List<CustomerMetalPurchaseEntry> entries,
}) {
  var grossWeight = 0.0;
  var fineWeight = 0.0;
  var amount = 0.0;
  var directPurchaseCount = 0;
  var tradeInCount = 0;
  var refundCount = 0;

  for (final entry in entries) {
    grossWeight += entry.grossWeight;
    fineWeight += entry.fineWeight;
    amount += entry.amount;

    final source = entry.source.toLowerCase();
    if (source.contains('trade') || source.contains('exchange')) {
      tradeInCount++;
    } else if (source.contains('refund') || source.contains('return')) {
      refundCount++;
    } else {
      directPurchaseCount++;
    }
  }

  return CustomerMetalPurchaseMetalSummary(
    metal: metal,
    grossWeight: grossWeight,
    fineWeight: fineWeight,
    amount: amount,
    entryCount: entries.length,
    directPurchaseCount: directPurchaseCount,
    tradeInCount: tradeInCount,
    refundCount: refundCount,
  );
}
