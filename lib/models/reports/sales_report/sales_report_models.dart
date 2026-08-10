enum SalesReportDatePreset {
  today,
  yesterday,
  thisMonth,
  lastMonth,
  custom,
}

enum SalesReportTaxMode {
  all,
  gst,
  nonGst,
}

enum SalesReportPaymentFilter {
  all,
  paid,
  due,
  partial,
}

class SalesReportFilter {
  final DateTime startDate;
  final DateTime endDate;
  final SalesReportDatePreset preset;
  final SalesReportTaxMode taxMode;
  final SalesReportPaymentFilter paymentFilter;
  final String metalType;
  final String query;

  const SalesReportFilter({
    required this.startDate,
    required this.endDate,
    this.preset = SalesReportDatePreset.today,
    this.taxMode = SalesReportTaxMode.all,
    this.paymentFilter = SalesReportPaymentFilter.all,
    this.metalType = 'ALL',
    this.query = '',
  });

  factory SalesReportFilter.initial() {
    final now = DateTime.now();
    return SalesReportFilter(
      startDate: DateTime(now.year, now.month),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      preset: SalesReportDatePreset.thisMonth,
    );
  }

  SalesReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    SalesReportDatePreset? preset,
    SalesReportTaxMode? taxMode,
    SalesReportPaymentFilter? paymentFilter,
    String? metalType,
    String? query,
  }) {
    return SalesReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preset: preset ?? this.preset,
      taxMode: taxMode ?? this.taxMode,
      paymentFilter: paymentFilter ?? this.paymentFilter,
      metalType: metalType ?? this.metalType,
      query: query ?? this.query,
    );
  }
}

class SalesReportSnapshot {
  final SalesReportFilter filter;
  final SalesReportSummary summary;
  final List<SalesReportMetalSummary> metals;
  final List<SalesReportInvoiceRow> invoices;
  final List<SalesReportItemRow> items;
  final List<String> availableMetals;

  const SalesReportSnapshot({
    required this.filter,
    required this.summary,
    required this.metals,
    required this.invoices,
    required this.items,
    required this.availableMetals,
  });

  factory SalesReportSnapshot.empty(SalesReportFilter filter) {
    return SalesReportSnapshot(
      filter: filter,
      summary: const SalesReportSummary(),
      metals: const [],
      invoices: const [],
      items: const [],
      availableMetals: const ['ALL'],
    );
  }
}

class SalesReportSummary {
  final int invoiceCount;
  final int gstInvoiceCount;
  final int nonGstInvoiceCount;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double roundOffAmount;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double advanceAmount;
  final double makingAmount;
  final double stockCostAmount;
  final double profitAmount;
  final double netWeight;

  const SalesReportSummary({
    this.invoiceCount = 0,
    this.gstInvoiceCount = 0,
    this.nonGstInvoiceCount = 0,
    this.grossAmount = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.gstAmount = 0,
    this.roundOffAmount = 0,
    this.finalAmount = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.cardAmount = 0,
    this.advanceAmount = 0,
    this.makingAmount = 0,
    this.stockCostAmount = 0,
    this.profitAmount = 0,
    this.netWeight = 0,
  });

  double get collectionAmount => cashAmount + upiAmount + cardAmount;
  double get profitMargin =>
      finalAmount <= 0 ? 0 : (profitAmount / finalAmount) * 100;
}

class SalesReportMetalSummary {
  final String metalType;
  final int invoiceCount;
  final int itemCount;
  final int pieces;
  final double grossWeight;
  final double netWeight;
  final double makingAmount;
  final double salesAmount;
  final double stockCostAmount;
  final double profitAmount;

  const SalesReportMetalSummary({
    required this.metalType,
    this.invoiceCount = 0,
    this.itemCount = 0,
    this.pieces = 0,
    this.grossWeight = 0,
    this.netWeight = 0,
    this.makingAmount = 0,
    this.salesAmount = 0,
    this.stockCostAmount = 0,
    this.profitAmount = 0,
  });

  double get profitMargin =>
      salesAmount <= 0 ? 0 : (profitAmount / salesAmount) * 100;
}

class SalesReportInvoiceRow {
  final int billId;
  final String billNo;
  final DateTime billDate;
  final String customerName;
  final String mobile;
  final String billType;
  final String paymentStatus;
  final bool isGst;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double roundOffAmount;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double advanceAmount;
  final double makingAmount;
  final double tradeInDeduction;
  final int itemCount;
  final String metalMix;

  const SalesReportInvoiceRow({
    required this.billId,
    required this.billNo,
    required this.billDate,
    required this.customerName,
    required this.mobile,
    required this.billType,
    required this.paymentStatus,
    required this.isGst,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.roundOffAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.cashAmount,
    required this.upiAmount,
    required this.cardAmount,
    required this.advanceAmount,
    required this.makingAmount,
    required this.tradeInDeduction,
    required this.itemCount,
    required this.metalMix,
  });
}

class SalesReportItemRow {
  final int billId;
  final String billNo;
  final DateTime billDate;
  final String customerName;
  final bool isGst;
  final int lineNo;
  final String metalType;
  final String itemName;
  final String huid;
  final String purity;
  final int quantity;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double fineWeight;
  final double rate;
  final String makingChargeType;
  final double makingCharge;
  final double itemTotal;
  final String stockSku;
  final double stockCostAmount;
  final double profitAmount;

  const SalesReportItemRow({
    required this.billId,
    required this.billNo,
    required this.billDate,
    required this.customerName,
    required this.isGst,
    required this.lineNo,
    required this.metalType,
    required this.itemName,
    required this.huid,
    required this.purity,
    required this.quantity,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.rate,
    required this.makingChargeType,
    required this.makingCharge,
    required this.itemTotal,
    required this.stockSku,
    required this.stockCostAmount,
    required this.profitAmount,
  });
}
