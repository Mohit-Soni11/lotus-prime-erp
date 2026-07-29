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

enum CustomerMetalPurchaseEntryView {
  available('Available'),
  transferred('Transferred'),
  returned('Returned'),
  all('All');

  final String label;

  const CustomerMetalPurchaseEntryView(this.label);
}

class CustomerMetalPurchaseMetalSummary {
  final CustomerMetalPurchaseMetal metal;
  final double grossWeight;
  final double fineWeight;
  final double amount;
  final int entryCount;
  final int customerCount;
  final int directPurchaseCount;
  final int tradeInCount;
  final int refundCount;

  const CustomerMetalPurchaseMetalSummary({
    required this.metal,
    required this.grossWeight,
    required this.fineWeight,
    required this.amount,
    required this.entryCount,
    required this.customerCount,
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
  final customerNames = <String>{};

  for (final entry in entries) {
    grossWeight += entry.grossWeight;
    fineWeight += entry.fineWeight;
    amount += entry.amount;
    final customerName = entry.customerName.trim().toUpperCase();
    if (customerName.isNotEmpty) {
      customerNames.add(customerName);
    }

    final source = entry.source.toLowerCase();
    if (source.contains('exchange')) {
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
    customerCount: customerNames.length,
    directPurchaseCount: directPurchaseCount,
    tradeInCount: tradeInCount,
    refundCount: refundCount,
  );
}
