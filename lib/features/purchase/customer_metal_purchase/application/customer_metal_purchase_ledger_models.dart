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

enum CustomerMetalPurchaseReportTab {
  ledger('Ledger'),
  metalSummary('Metal Summary'),
  sellerSummary('Seller Summary'),
  pendingPayout('Pending Payout'),
  paymentSummary('Payment Summary');

  final String label;

  const CustomerMetalPurchaseReportTab(this.label);
}

enum CustomerMetalPurchaseQuickPeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  lastYear('Last Year'),
  custom('Custom');

  final String label;

  const CustomerMetalPurchaseQuickPeriod(this.label);
}

class CustomerMetalPurchaseMetalSummary {
  final CustomerMetalPurchaseMetal metal;
  final double grossWeight;
  final double netWeight;
  final double fineWeight;
  final double amount;
  final double paidAmount;
  final double pendingAmount;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final int entryCount;
  final int customerCount;
  final int directPurchaseCount;
  final int tradeInCount;
  final int refundCount;

  const CustomerMetalPurchaseMetalSummary({
    required this.metal,
    required this.grossWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.amount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.entryCount,
    required this.customerCount,
    required this.directPurchaseCount,
    required this.tradeInCount,
    required this.refundCount,
  });

  double get averagePurchaseRate => fineWeight <= 0 ? 0 : amount / fineWeight;

  bool get hasBusiness => entryCount > 0 || amount > 0.005;
}

class CustomerMetalPurchaseDashboardSummary {
  final double grossWeight;
  final double netWeight;
  final double fineWeight;
  final double amount;
  final double paidAmount;
  final double pendingAmount;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final int entryCount;
  final int customerCount;
  final int voucherCount;

  const CustomerMetalPurchaseDashboardSummary({
    required this.grossWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.amount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.entryCount,
    required this.customerCount,
    required this.voucherCount,
  });
}

class CustomerMetalPurchaseSellerSummary {
  final String sellerName;
  final String? mobile;
  final double amount;
  final double paidAmount;
  final double pendingAmount;
  final double fineWeight;
  final int entryCount;
  final int voucherCount;

  const CustomerMetalPurchaseSellerSummary({
    required this.sellerName,
    required this.mobile,
    required this.amount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.fineWeight,
    required this.entryCount,
    required this.voucherCount,
  });
}

CustomerMetalPurchaseMetalSummary buildCustomerMetalPurchaseSummary({
  required CustomerMetalPurchaseMetal metal,
  required List<CustomerMetalPurchaseEntry> entries,
}) {
  var grossWeight = 0.0;
  var netWeight = 0.0;
  var fineWeight = 0.0;
  var amount = 0.0;
  var paidAmount = 0.0;
  var pendingAmount = 0.0;
  var cashPaid = 0.0;
  var upiPaid = 0.0;
  var bankPaid = 0.0;
  var cardPaid = 0.0;
  var directPurchaseCount = 0;
  var tradeInCount = 0;
  var refundCount = 0;
  final customerNames = <String>{};

  for (final entry in entries) {
    grossWeight += entry.grossWeight;
    netWeight += entry.netWeight;
    fineWeight += entry.fineWeight;
    amount += entry.amount;
    paidAmount += entry.paidAmount;
    pendingAmount += entry.pendingAmount;
    cashPaid += entry.cashPaid;
    upiPaid += entry.upiPaid;
    bankPaid += entry.bankPaid;
    cardPaid += entry.cardPaid;
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
    netWeight: netWeight,
    fineWeight: fineWeight,
    amount: amount,
    paidAmount: paidAmount,
    pendingAmount: pendingAmount,
    cashPaid: cashPaid,
    upiPaid: upiPaid,
    bankPaid: bankPaid,
    cardPaid: cardPaid,
    entryCount: entries.length,
    customerCount: customerNames.length,
    directPurchaseCount: directPurchaseCount,
    tradeInCount: tradeInCount,
    refundCount: refundCount,
  );
}
